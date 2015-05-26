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
  HTMLCOLOR = "<div class='ldcp-colors'>" + ("<div class='ldcp-color'></div>" * 7) + "</div>"
  node.innerHTML = HTML2D + HTML1D + HTMLCOLOR
  node.querySelector(".ldcp-2d .ldcp-mask").addEventListener("mousedown", (e) ~> ldColorPicker.mouse.start @, 2 )
  node.querySelector(".ldcp-1d .ldcp-mask").addEventListener("mousedown", (e) ~> ldColorPicker.mouse.start @, 1 )
  setTimeout (~>
    @P2D = {ptr: node.querySelector(".ldcp-ptr")}
    @P1D = {ptr: node.querySelector(".ldcp-bar")}
    @update-dimension!
    @ <<< {width: node.offsetWidth, height: node.offsetHeight}
    @color = do
      nodes: node.querySelectorAll(".ldcp-color")
      vals: ldColorPicker.palette.getVal @
    #if standalone => @color.vals: [{hue: parseInt(Math.random!*360), sat: 50, lit: 50} for i from 0 til 7]
    for idx from 0 til @color.nodes.length =>
      c = @color.nodes[idx]
      c.idx = idx
      c.addEventListener \click, (e) ~> @set-idx e.target.idx
    c = @color.vals[@idx]
    @set-hsl c.hue, c.sat, c.lit
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
    val: [{hue: parseInt(Math.random!*360), sat: 50, lit: 50} for i from 0 til 7]
  mouse: do
    start: (target, type) ->
      list =
        [\selectstart, ((e) -> cancelAll e)]
        [\mousemove, ((e) -> target.move e, type)]
        [\mouseup, ((e) -> list.map -> document.removeEventListener it.0, it.1)]
      list.map -> document.addEventListener it.0, it.1

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

    toggle: ->
      if @node.style.display == \block =>
        @node.style.display = \none
      else
        @node.style.display = \block
        @update-dimension!
        @palette.splice 7
        @color.vals.splice 0, 0, @random! #[@random!] ++ @color.vals
        c = @color.vals[@idx]
        @set-hsl c.hue, c.sat, c.lit  
        # if standalone => @update-palette!
        ldColorPicker.palette.update!

    random: -> {hue: Math.random!*360, sat: 50, lit: 50}
    update-palette: -> for idx from 0 til @color.nodes.length  => @update-color idx
    update-color: (idx) ->
      c = @color.vals[idx]
      @color.nodes[idx]style.background = "hsl(#{c.hue or 0},#{c.sat or 0}%,#{c.lit or 0}%)"
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
      it = parseInt(it * 255) >? 0 <? 255
      it = it.toString 16
      if it.length < 2 => "0#it" else it
    toHexString: (c) -> 
      [r,g,b] = @toRgb c
      "\##{@hex r}#{@hex g}#{@hex b}"
    set-idx: (idx) ->
      @idx = idx
      c = @color.vals[idx]
      @set-hsl c.hue, c.sat, c.lit
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

    move: (e, type) ->
      if !e.buttons => return
      rect = @node.getBoundingClientRect!
      [y, x] = [e.clientY - rect.top, e.clientX - rect.left]
      @set-pos type, x, y

      if e.stopPropagation => e.stopPropagation!
      if e.preventDefault => e.preventDefault!
      e.cancelBubble = true
      e.returnValue = false
      false

    palette: []
    add: (node, event) ->
      root = node.parentNode.parentNode
      @palette.push root{hue,sat,lit}
      if @palette.length > 7 => @palette.splice(7)
      nodes = node.parentNode.querySelectorAll(".ldcp-color")
      for i from 0 til nodes.length =>
        n = nodes[i]
        p = @palette[i]
        if !p => break
        n.style.background = "hsl(#{p.hue or 0},#{p.sat or 0}%,#{p.lit or 0}%)"

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
  item.addEventListener \click, -> @_ldcpnode._ldcp.toggle!

