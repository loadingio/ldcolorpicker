cancelAll = (e) -> 
  if e.stopPropagation => e.stopPropagation!
  if e.preventDefault => e.preventDefault!
  e.cancelBubble = true
  e.returnValue = false
  false

ldColorPicker = ( (node, target = null) ->
  @ <<< {node, target, idx: 0}
  HTML2D = "<div class='ldcp-2d'><div class='ldcp-ptr'></div><div class='ldcp-mask'></div></div>"
  HTML1D = "<div class='ldcp-1d'><div></div><div></div><div class='ldcp-bar'></div><div class='ldcp-mask'></div></div>"
  HTMLCOLOR = "<div class='ldcp-colors'><div class='ldcp-colorptr'></div>" + ("<div class='ldcp-color'></div>" * 9) + "</div>"
  HTMLPALS = "<div class='ldcp-palettes'></div>"
  node.innerHTML = "<div class='ldcp-picker'>" + HTML2D + HTML1D + HTMLCOLOR + HTMLPALS + "</div>"
  node.querySelector(".ldcp-2d .ldcp-mask")
    ..addEventListener("mousedown", (e) ~> ldColorPicker.mouse.start @, 2 )
    ..addEventListener("click", (e) ~> @move e, 2, true )
  node.querySelector(".ldcp-1d .ldcp-mask")
    ..addEventListener("mousedown", (e) ~> ldColorPicker.mouse.start @, 1 )
    ..addEventListener("click", (e) ~> @move e, 1, true )
  setTimeout (~>
    @P2D = {ptr: node.querySelector(".ldcp-ptr")}
    @P1D = {ptr: node.querySelector(".ldcp-bar")}
    @colorptr = node.querySelector(".ldcp-colorptr")
    @update-dimension!
    @ <<< {width: node.offsetWidth, height: node.offsetHeight}
    @color = do
      nodes: node.querySelectorAll(".ldcp-color")
      vals: ldColorPicker.palette.getVal @
    for idx from 0 til @color.nodes.length =>
      c = @color.nodes[idx]
      c.idx = idx
      c.addEventListener \click, (e) ~> @set-idx e.target.idx
    c = @color.vals[@idx]
    @set-idx @idx # set ptr correctly
    @set-hsl c.hue, c.sat, c.lit
    @update-palette!
  ), 0
  @
) <<< do
  dom: null
  palette: do
    members: []
    getVal: (node) -> 
      if node => @members.push node
      @val
    update: ->
      for item in @members => item.update-palette!
    val: [{hue: parseInt(Math.random!*360), sat: 50, lit: 50} for i from 0 til 9]
  mouse: do
    start: (target, type) ->
      list =
        [\selectstart, ((e) -> cancelAll e)]
        [\mousemove, ((e) -> target.move e, type)]
        [\mouseup, ((e) -> 
          list.map -> document.removeEventListener it.0, it.1
          setTimeout (->if target.clickToggler => document.addEventListener \click, target.clickToggler), 0
        )]
      list.map -> document.addEventListener it.0, it.1
      if target.clickToggler => document.removeEventListener \click, target.clickToggler

  init: (node, target = null) ->
    if node =>
      node._ldcp = new ldColorPicker node, target
    else
      all = document.querySelectorAll(".ldColorPicker")
      for node in all => node._ldcp = new ldColorPicker node
  prototype: do
    update-dimension: ->
      [n2,n1] = [@node.querySelector(".ldcp-2d"), @node.querySelector(".ldcp-2d")]
      @P2D <<< {w: n2.offsetWidth, h: n2.offsetHeight}
      @P1D <<< {w: n1.offsetWidth, h: n1.offsetHeight}
    
    clickToggle: (e) -> 
      @clickToggler = ~>
        console.log @
        document.removeEventListener \click, @clickToggler
        @toggle!

    toggle: ->

      if @node.style.display == \block =>
        @node.style.display = \none
      else
        @node.style.display = \block
        document.addEventListener \click, @clickToggle!
        @update-dimension!
        ret = @color.vals.map((it,idx) ~> [idx, @toHexString(it)]).filter(~> it.1 == @target.value.to-lower-case!).0
        if ret => @idx = ret.0
        else @color.vals.splice 0, 0, @convert.color @target.value
        c = @color.vals[@idx]
        @set-hsl c.hue, c.sat, c.lit  
        ldColorPicker.palette.update!

    random: -> {hue: Math.random!*360, sat: 50, lit: 50}
    update-palette: -> for idx from 0 til @color.nodes.length  => @update-color idx
    update-color: (idx) ->
      c = @color.vals[idx]
      @color.nodes[idx]style.background = "hsl(#{c.hue or 0},#{c.sat or 0}%,#{c.lit or 0}%)"
    convert: do
      color: ->
        if /#[a-fA-F0-9]{6}/.exec(it) => 
          r = parseInt(it.substring(1,3), 16) / 255
          g = parseInt(it.substring(3,5), 16) / 255
          b = parseInt(it.substring(5,7), 16) / 255
          ret = {hue,sat,lit} = @rgb-hsl {r,g,b}
          ret
        {hue:0,sat:0,lit:0}

      rgb-hsl: ({r,g,b}) ->
        Cmax = Math.max(r,g,b)
        Cmin = Math.min(r,g,b)
        delta = Cmax - Cmin
        lit = ( Cmax + Cmin ) / 2
        if delta == 0 => [hue,sat] = [0,0]
        else 
          hue = switch
            | Cmax == r => 60 * ((( g - b ) / delta ) % 6)
            | Cmax == g => 60 * ((( b - r ) / delta ) + 2)
            | Cmax == b => 60 * ((( r - g ) / delta ) + 4)
          sat = 100 * delta / ( 1 - Math.abs( 2 * lit - 1) )
        lit *= 100
        return {hue, sat, lit}

    toRgb: (c) -> 
      C = ( 1 - Math.abs(2 * c.lit/100 - 1)) * c.sat / 100
      X = C * ( 1 - Math.abs( ( (c.hue / 60) % 2 ) - 1 ) )
      m = c.lit/100 - C / 2
      [r,g,b] = switch parseInt(c.hue / 60)
        | 0 => [C,X,0]
        | 1 => [X,C,0]
        | 2 => [0,C,X]
        | 3 => [0,X,C]
        | 4 => [X,0,C]
        | 5 => [C,0,X]
        | 6 => [C,X,0]
      [r,g,b] = [r + m, g + m, b + m]
    hex: -> 
      it = Math.round(it * 255) >? 0 <? 255
      it = it.toString 16
      if it.length < 2 => "0#it" else it
    toHexString: (c) -> 
      [r,g,b] = @toRgb c
      "\##{@hex r}#{@hex g}#{@hex b}"
    set-idx: (idx) ->
      @idx = idx
      c = @color.vals[idx]
      @set-hsl c.hue, c.sat, c.lit
      @colorptr.style.left = "#{((idx + 0.5) * 100 / @color.nodes.length)}%"
    set-hsl: (hue, sat, lit, no-recurse = false) ->
      @color.vals[@idx] <<< {hue, sat, lit}
      if @target => @target.value = @toHexString @color.vals[@idx]
      if !no-recurse =>
        x = ( @P2D.w * hue / 360 + @P2D.w * 0.02 ) / 1.04
        y1 = ( @P2D.h * (100 - sat) / 100 + @P2D.h * 0.02 ) / 1.04
        y2 = ( @P1D.h * (100 - lit) / 100 + @P1D.h * 0.02 ) / 1.04
        @set-pos 2, x, y1, true
        @set-pos 1, x, y2, true
        @update-color @idx
      
    set-pos: (type, x, y, no-recurse = false) ->
      ctx = if type == 2 => @P2D else @P1D
      x = x >? 0 <? ctx.w
      y = y >? 0 <? ctx.h
      ctx.ptr.style.top = "#{y}px"
      if type == 2 => ctx.ptr.style.left = "#{x}px"
      if !no-recurse =>
        [lx, ly] = [x * 1.04 - ctx.w * 0.02, y * 1.04 - ctx.h * 0.02]
        lx = (100 * lx / ctx.w) >? 0 <? 100
        ly = (100 * ly / ctx.h) >? 0 <? 100
        c = @color.vals[@idx]
        hue = if type == 2 => lx * 3.60 else c.hue
        sat = if type == 2 => 100 - ly else c.sat
        lit = if type == 1 => 100 - ly else c.lit
        @set-hsl hue, sat, lit, true
        @update-color @idx

    move: (e, type, isClick = false) ->
      if !e.buttons and !isClick => return
      rect = @node.getBoundingClientRect!
      [y, x] = [e.clientY - rect.top, e.clientX - rect.left]
      @set-pos type, x, y

      if e.stopPropagation => e.stopPropagation!
      if e.preventDefault => e.preventDefault!
      e.cancelBubble = true
      e.returnValue = false
      false

    palette: []

<- $(document).ready
ldColorPicker.init!

list = document.querySelectorAll("*[data-toggle='colorpicker']")
for item in list
  item._ldcpnode = node = document.createElement("div")
  node.setAttribute("class", "ldColorPicker #{item.getAttribute('data-cpclass')} bottom bubble")
  ldColorPicker.init(node, item)
  document.body.appendChild(node)
  top = (item.offsetTop + item.offsetHeight + 10) + "px"
  left = (item.offsetLeft + ( item.offsetWidth - node.offsetWidth ) / 2) + "px"
  node.style <<< {position: "absolute", display: "none", top, left}
  item.addEventListener \click, (e) -> 
    @_ldcpnode._ldcp.toggle!
    cancelAll e

/*
color 
  hex
  h,s,l
  r,g,b
  to-hsl
  to-rgb
  to-hex-string

*/
