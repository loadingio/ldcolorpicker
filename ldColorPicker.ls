do ->
  cancelAll = (e) -> 
    if e.stopPropagation => e.stopPropagation!
    if e.preventDefault => e.preventDefault!
    e.cancelBubble = true
    e.returnValue = false
    false

  ldColorPicker = ( (target = null, config = {}, node = null) ->
    srcnode = (if target => that else node)
    custom-class = config.class or (srcnode and srcnode.getAttribute(\data-cpclass)) or ""
    custom-context = config.context or (srcnode and srcnode.getAttribute(\data-context)) or \default
    custom-callback = config.oncolorchange or (srcnode and srcnode.getAttribute(\data-oncolorchange)) or null
    custom-idx = config.index or (srcnode and parseInt(srcnode.getAttribute(\data-palette-idx))) or 0
    custom-palette = (config.palette or (srcnode and srcnode.getAttribute(\data-palette))) or null
    if typeof(custom-palette) == typeof("") =>
      custom-palette = custom-palette.trim!
      if custom-palette.0 == \[ => @initpal = {colors:[{hex:it} for it in JSON.parse(custom-palette)]}
      else if /\//.exec(custom-palette) => @url = custom-palette
      else @initpal = {colors:[{hex:it} for it in custom-palette.split(/[ ,]/)]}
    else if Array.isArray(custom-palette) => @initpal = {colors:[{hex:it} for it in custom-palette]}
    else @initpal = custom-palette
    if isNaN(custom-idx) => custom-idx = 0
    if typeof(custom-callback) == typeof("") => custom-callback = new Function(<[color]>,custom-callback)
    if !node =>
      if !(\bubble in custom-class.split(' ')) => custom-class += " bubble"
      document.body.appendChild(node = document.createElement("div"))
      node._ldcp = @
      node.style <<< {position: "absolute", display: "none"}
      if target =>
        target._ldcpnode = node
        target.getColorPicker = ~> return @
        target.addEventListener \click, (e) -> 
          @_ldcpnode._ldcp.toggle!
          cancelAll e
    else => custom-class += node.getAttribute("class")
    if !(\ldColorPickr in custom-class.split(' ')) => custom-class += ' ldColorPicker'
    node.setAttribute("class", "#{custom-class}")
    @ <<< {node, target, idx: custom-idx, context: custom-context, class: custom-class, callback: custom-callback}
    @event-handler = {}
    /*
    HTML2D = "<div class='ldcp-2d'><div class='ldcp-ptr'></div><img src='#{ldColorPicker.base64.gradient}'><div class='ldcp-mask'></div></div>"
    HTML1D = "<div class='ldcp-1d'><div></div><div></div><div class='ldcp-bar'></div><img src='#{ldColorPicker.base64.hue}'><div class='ldcp-mask'></div></div>"
    #HTML1D += HTML1D
    HTMLCOLOR = "<div class='ldcp-colors'><div class='ldcp-colorptr'></div>" + ("<div class='ldcp-color'></div>" * 5) + "</div>"
    HTMLPALS = "<div class='ldcp-functions'>" + ("<div class='ldcp-btn'></div>") * 4 + "</div>"
    HTMLCONFIG = "<span>Paste Link of You Palette:</span><input placeholder='e.g., loading.io/palette/xddlf'/><div class='ldcp-chooser-btnset'><button>Sample</button><button>Load</button><button>Cancel</button></div>"
    node.innerHTML = "<div class='ldcp-panel ldcp-picker'>" + HTML2D + HTML1D + HTMLCOLOR + HTMLPALS + "</div>" + 
      "<div class='ldcp-panel ldcp-chooser'>" + HTMLCONFIG + "</div>"
    */
    HTMLCONFIG = "<span>Paste Link of You Palette:</span><input placeholder='e.g., loading.io/palette/xddlf'/><div class='ldcp-chooser-btnset'><button>Sample</button><button>Load</button><button>Cancel</button></div>"
    HTML = "<div class='ldcp-panel'><div class='ldcp-v ldcp-g1'><div class='ldcp-h ldcp-g11 ldcp-2d'><div style='top:20px;left:20px' class='ldcp-ptr-circle'></div><img src='#{ldColorPicker.base64.gradient}'><div class='ldcp-mask'></div></div><div class='ldcp-h ldcp-g12 ldcp-1d'><div class='ldcp-ptr-bar'></div><img src='#{ldColorPicker.base64.hue}'><div class='ldcp-mask'></div></div><div class='ldcp-h ldcp-g13 ldcp-1d ldcp-alpha'><div class='ldcp-ptr-bar'></div><img src='opacity.png'><div class='ldcp-mask'></div></div></div><div class='ldcp-v ldcp-g2'><div class='ldcp-colors ldcp-h ldcp-g21'><div class='ldcp-palette'><small class='ldcp-colorptr'></small><div class='ldcp-color'></div></div><small class='ldcp-sep'></small><div class='ldcp-color-none'></div><span class='ldcp-cbtn ldcp-btn-add'>+</span><span class='ldcp-cbtn ldcp-btn-remove'>-</span><span style='font-family:wingdings' class='ldcp-cbtn ldcp-btn-edit'>&#228;</span></div></div><div class='ldcp-v ldcp-g3'><div class='ldcp-h ldcp-g31'><span>H</span><input class='ldcp-input-h' value='255'><span>S</span><input class='ldcp-input-s' value='255'><span>L</span><input class='ldcp-input-l' value='255'><span class='ldcp-alpha'>A</span><input value='255' class='ldcp-alpha ldcp-input-a'><span>Hex</span><input value='#00ff00' class='ldcp-input-hex'></div></div></div><div class='ldcp-chooser'><button/><button/><button/></div>"
    HTML += "<div class='ldcp-panel ldcp-chooser'>" + HTMLCONFIG + "</div>"
    node.innerHTML = HTML
    node.addEventListener(\click, (e) -> cancelAll e)
    for selector in [".ldcp-2d .ldcp-mask", ".ldcp-2d .ldcp-ptr-circle"]
      node.querySelector(selector)
        ..addEventListener(\mousedown, (e) ~> ldColorPicker.mouse.start @, 2 )
        ..addEventListener("click", (e) ~> @move e, 2, true )

    for selector in [".ldcp-1d .ldcp-mask", ".ldcp-1d .ldcp-ptr-bar"] =>
      for item,idx in node.querySelectorAll(selector) =>
        _ = (item,idx) ~>
          item.addEventListener(\mousedown, (e) ~> ldColorPicker.mouse.start @, idx )
          item.addEventListener("click", (e) ~> 
            @move e, idx, true
          )
        _(item, idx)

    node.querySelector(".ldcp-cbtn:nth-of-type(1)").addEventListener("click", ~> @add-color! )
    node.querySelector(".ldcp-cbtn:nth-of-type(2)").addEventListener("click", ~> @remove-color! )
    #node.querySelector(".ldcp-btn:nth-of-type(3)").addEventListener("click", ~> @edit!)
    #node.querySelector(".ldcp-btn:nth-of-type(4)").addEventListener("click", ~> @toggle-config! )
    /*
    node.querySelector(".ldcp-chooser button:nth-of-type(1)").addEventListener("click", ~> 
      @chooser.input.value = ldColorPicker.default-palette-path or 'http://loading.io/palette/559087d71deb8c3a54548932'
    )
    node.querySelector(".ldcp-chooser button:nth-of-type(2)").addEventListener("click", ~> 
      @load-palette @chooser.input.value
      @toggle-config!
    )
    node.querySelector(".ldcp-chooser button:nth-of-type(3)").addEventListener("click", ~> @toggle-config!)
    */
    setTimeout (~>
      @chooser = do
        panel: node.querySelector(".ldcp-chooser")
        input: node.querySelector(".ldcp-chooser input")
      @inputhex = node.querySelector(".ldcp-input-hex")
      @inputH = node.querySelector(".ldcp-input-h")
      @inputS = node.querySelector(".ldcp-input-s")
      @inputL = node.querySelector(".ldcp-input-l")
      @inputA = node.querySelector(".ldcp-input-a")
      @colornone = node.querySelector(".ldcp-color-none")
        ..addEventListener(\click, (~> @toggle-none!))
      @palpad = node.querySelector(".ldcp-palette")
      @P2D = {ptr: node.querySelector(".ldcp-ptr-circle"), panel: node.querySelector(".ldcp-2d img")}
      @P1D = {ptr: node.querySelectorAll(".ldcp-ptr-bar"), panel: node.querySelectorAll(".ldcp-1d img")}
      @colorptr = node.querySelector(".ldcp-colorptr")
      @update-dimension!
      @ <<< {width: node.offsetWidth, height: node.offsetHeight}
      @color = do
        nodes: node.querySelectorAll(".ldcp-palette .ldcp-color")
        palette: node.querySelector(".ldcp-colors .ldcp-palette")
        vals: ldColorPicker.palette.getVal(@, @context)
      # arrayize
      @color.nodes = [@color.nodes[i] for i from 0 til @color.nodes.length]
      for idx from 0 til @color.nodes.length =>
        c = @color.nodes[idx]
        c.idx = idx
        c.addEventListener \click, (e) ~> @set-idx(e.target.idx)
      c = @color.vals[@idx]
      @update-palette!
      @set-idx @idx # set ptr correctly
      @set-hsl c.hue, c.sat, c.lit
      if @callback => @on \change, ~> @callback.apply @target, [it]
      if @url => 
        @chooser.input.value = @url
        setTimeout((~>@load-palette @chooser.input.value),0)
      if @initpal =>
        @set-palette @initpal
    ), 0
    @
  ) <<< do
    dom: null
    set-palette: (pal,context='default') ->
      if pal.length and typeof(pal.0) == typeof("") and pal.0.length > 3 =>
        convert = ldColorPicker.prototype.convert
        ldColorPicker.palette.val[context].splice 0
        for hex in pal => ldColorPicker.palette.val[context].push convert.color hex
        ldColorPicker.palette.update!
      else @default-palette-path = pal
    palette: do
      members: []
      # object with hex version of getVal, just like ldcp.getPalette()
      get: (context)-> 
        {colors: [ldColorPicker.prototype.toHexString it for it in (@val[context] or [])]}
      getVal: (node,context='default') -> 
        if node and typeof(node)!=typeof("") => @members.push node
        if typeof(node) == typeof("") => context = node
        if !@val[context] => @val[context] = @random!
        @val[context]
      update: ->
        for item in @members => item.update-palette!
      random: ->
        [{hue: parseInt(Math.random!*30 + i * 90 - 15), sat: 0.3 + Math.random!*0.4, lit: 0.4 + Math.random!*0.4} for i from 0 til 5]
      val: do
        default: [{hue: parseInt(Math.random!*30 + i * 90 - 15), sat: 0.3 + Math.random!*0.4, lit: 0.4 + Math.random!*0.4} for i from 0 til 5]
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
        node._ldcp = new ldColorPicker target, {}, node
      else
        all = document.querySelectorAll(".ldColorPicker")
        for node in all => if !node._ldcp => node._ldcp = new ldColorPicker null, {}, node

        list = document.querySelectorAll("*[data-toggle='colorpicker']")
        for item in list => new ldColorPicker item, {}

    prototype: do
      load-palette: (url) ->
        xhr = new XMLHttpRequest!
          ..onload = ~> @set-palette JSON.parse(xhr.responseText) 
          ..open \GET, url.replace(/palette/, "d/palette"), true
          ..send!
      add-color: -> if @color.vals.length < 12 =>
        @color.vals.splice 0, 0, @random!
        @update-palette!
      remove-color: -> if @color.vals.length > 1 =>
        @color.vals.splice @idx, 1
        @update-palette!
      edit: -> 
        hex = [@toHexString(v).replace(/#/,'') for v in @color.vals].join(",")
        window.open "http://loading.io/color/?colors=#hex"
      update-dimension: ->
        [n2,n1] = [@node.querySelector(".ldcp-2d"), @node.querySelector(".ldcp-1d")]
        @P2D <<< {w: n2.offsetWidth, h: n2.offsetHeight}
        @P1D <<< {w: n1.offsetWidth, h: n1.offsetHeight}
      
      clickToggle: (e) -> 
        @clickToggler = ~>
          document.removeEventListener \click, @clickToggler
          @toggle!
      toggle-config: ->
        if @chooser.panel.style.height == \98% => @chooser.panel.style <<< {height: 0}
        else @chooser.panel.style <<< {height: \98%}
      event-handler: {}
      handle: (name, value) -> if @event-handler[name] => for cb in that => cb value
      on: (name, cb) -> @event-handler.[][name].push cb
      toggle: (isOn=null) ->
        if isOn == false or ( isOn == null and @node.style.display == \block ) =>
          document.removeEventListener \click, @clickToggler
          @node.style.display = \none
          if @target =>
            ret = @color.vals.map((it,idx) ~> [idx, @toHexString(it)])
              .filter(~> it.1 == @target.value.to-lower-case!).0
            if ret => @idx = ret.0
            else @color.vals.splice 0, 0, @convert.color @target.value
          c = @color.vals[@idx]
          @set-hsl c.hue, c.sat, c.lit  

        else
          @node.style.display = \block
          if @target =>
            [sx,sy] = if window.scrollX? => [window.scrollX, window.scrollY]
            else if window.pageXOffset? => [window.pageXOffset, window.pageYOffset]
            else [document.body.scrollLeft, document.body.scrollTop]
            bcr = @target.getBoundingClientRect!
            class-list = @class.split(' ')
            left = (bcr.left + sx) + "px"
            top = (bcr.top + sy) + "px"
            if \top in class-list => top = (bcr.top - @node.offsetHeight - 10 + sy ) + "px"
            else if \left in class-list => left = (bcr.left - @node.offsetWidth - 10 + sx ) + "px"
            else if \right in class-list => left = (bcr.left + @target.offsetWidth + 10 + sx) + "px"
            else top = (bcr.top + @target.offsetHeight + 10 + sy) + "px"
            @node.style <<< {top, left}
          document.removeEventListener \click, @clickToggler
          document.addEventListener \click, @clickToggle!
          @update-dimension!

          if @target =>
            ret = @color.vals.map((it,idx) ~> [idx, @toHexString(it)]).filter(~> it.1 == @target.value.to-lower-case!).0
            if ret => @idx = ret.0
            else @color.vals.splice 0, 0, @convert.color @target.value
          c = @color.vals[@idx]
          @set-hsl c.hue, c.sat, c.lit  
        ldColorPicker.palette.update!

      random: -> {hue: Math.random!*360, sat: 0.5, lit: 0.5}
      get-palette: -> {colors: [{hex: @toHexString v} for v in @color.vals]}
      set-palette: (pal, clean = false) ->
        result = [@convert.color(it.hex) for it in pal.colors]
        @color.vals.splice 0
        if clean => @color.vals = []
        for it in result => @color.vals.push it
        ldColorPicker.palette.update!
      update-palette: -> 
        [nlen, vlen] = [@color.nodes.length, @color.vals.length]
        if vlen > nlen =>
          for i from nlen til vlen =>
            node = document.createElement("div")
              ..setAttribute \class, \ldcp-color
              ..addEventListener \click, (e) ~> @set-idx e.target.idx
              ..idx = i
            @color.palette.appendChild(node)
            @color.nodes.push node
        else if vlen < nlen =>
          for i from vlen til nlen
            @color.palette.removeChild @color.nodes[i]
          @color.nodes.splice vlen
        for idx from 0 til vlen => @update-color idx
        if @idx >= vlen => @idx = vlen - 1
        c = @color.vals[@idx]
        value = if c.alpha? and c.alpha < 1 => @toRgbaString(c) else @toHexString(c)
        if @old-value != value => @handle \change, value
        @old-value = value
        @set-idx @idx
        @inputH.value = c.hue
        @inputS.value = c.sat
        @inputL.value = c.lit
        @inputA.value = (if c.alpha? => c.alpha else 1)
        @inputhex.value = @getHexString!
      update-color: (idx) ->
        c = @color.vals[idx]
        n = @color.nodes[idx]
        n.style.background = @toHslaString(c)
        if c.is-none => n.style.border = "1px dashed \#ccc"
        else n.style.border = "1px dashed transparent"
      convert: do
        color: ->
          if /#[a-fA-F0-9]{6}/.exec(it) => 
            r = parseInt(it.substring(1,3), 16) / 255
            g = parseInt(it.substring(3,5), 16) / 255
            b = parseInt(it.substring(5,7), 16) / 255
            ret = {hue,sat,lit} = @rgb-hsl {r,g,b}
            return ret
          {hue:0,sat:0,lit:0,sat-v:0,val:0}

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
            sat = delta / ( 1 - Math.abs( 2 * lit - 1) )
            val = Cmax
            sat-v = Cmax - Cmin / val
          hue = ( hue + 360 ) % 360
          return {hue, sat, lit, sat-v, val}

      toRgba: (c) ->
        C = ( 1 - Math.abs(2 * c.lit - 1)) * c.sat
        X = C * ( 1 - Math.abs( ( (c.hue / 60) % 2 ) - 1 ) )
        m = c.lit - C / 2
        [r,g,b] = switch parseInt(c.hue / 60)
          | 0 => [C,X,0]
          | 1 => [X,C,0]
          | 2 => [0,C,X]
          | 3 => [0,X,C]
          | 4 => [X,0,C]
          | 5 => [C,0,X]
          | 6 => [C,X,0]
        [r,g,b,a] = [r + m, g + m, b + m, (if c.alpha? => c.alpha else 1)]
      hex: -> 
        it = Math.round(it * 255) >? 0 <? 255
        it = it.toString 16
        if it.length < 2 => "0#it" else it

      getHslaString: -> @toHslaString @color.vals[@idx]
      toHslaString: (c) ->
        if c.is-none => return \none
        return "hsla(#{c.hue or 0},#{100 * c.sat or 0}%,#{100 * c.lit or 0}%,#{if c.alpha? => c.alpha else 1})"

      getRgbaString: -> @toRgbaString @color.vals[@idx]
      toRgbaString: (c) ->
        if c.is-none => return \none
        ret = @toRgba c
        for i from 0 til 3 => ret[i] = parseInt(ret[i] * 255)
        return "rgba(#{ret.join(\,)})"

      getHexString: (addhash = true) -> 
        ret = @toHexString @color.vals[@idx]
        return if !addhash => ret.replace /#/g, '' else ret
      toHexString: (c) ->
        if c.is-none => return \none
        [r,g,b,a] = @toRgba c
        "\##{@hex r}#{@hex g}#{@hex b}"
      getValue: ->
        c = @color.vals[@idx]
        if c.alpha? and c.alpha < 1 => @getRgbaString! else @getHexString!

      get-idx: -> @idx
      set-idx: (idx) ->
        if @idx != idx => 
          c = @color.vals[idx]
          @handle \change, if c.alpha? and c.alpha < 1 => @toRgbaString(c) else @toHexString(c)
          @handle \change-idx, idx
        @idx = idx
        if @target => @target.setAttribute("data-palette-idx",idx)
        c = @color.vals[idx]
        @set-hsl c.hue, c.sat, c.lit
        @colorptr.style.left = "#{((idx + 0.5) * 100 / @color.nodes.length)}%"

      set-alpha: (alpha, no-recurse = false) ->
        c = @color.vals[@idx]
        alpha-old = c.alpha
        c.alpha = alpha
        y = @P1D.h * (1 - alpha)
        if alpha-old != alpha =>
          if c.is-none => c.is-none = false
          ldColorPicker.palette.update!
        @set-pos 1, 0, y, true

      toggle-none: ->
        c = @color.vals[@idx]
        c.is-none = true
        ldColorPicker.palette.update!

      set-hsl: (hue, sat, lit, no-recurse = false) ->
        c = @color.vals[@idx]
        value-old = @toRgba c .join(\,)
        c <<< {hue, sat, lit}
        @P2D.panel.style.backgroundColor = @toHexString({hue, sat: 1, lit: 0.5})
        @P1D.panel.1.style.backgroundColor = @toHexString({hue, sat, lit})
        value = @toRgba c .join(\,)
        if @target => 
          @target.value = @getValue!
          @target.setAttribute("data-color", value)
        if value-old != value =>
          if c.is-none => c.is-none = false
          ldColorPicker.palette.update!

        if !no-recurse =>
          lit-v = ( 2 * lit + sat * ( 1 - Math.abs( 2 * lit - 1 ) ) ) / 2
          sat-v = 2 * ( lit-v - lit ) / lit-v

          if !@P1D.h or !@P2D.h => @update-dimension!
          x = ( @P2D.w * (sat-v) ) 
          y1 = ( @P2D.h * (1 - lit-v) ) / 1.00
          y2 = ( @P1D.h * (hue / 360 ) ) / 1.00

          @set-pos 2, x, y1, true
          @set-pos 0, x, y2, true

          @update-color @idx

      set-pos: (type, x, y, no-recurse = false) ->
        ctx = if type == 2 => @P2D else @P1D
        ptr = if type == 2 => ctx.ptr else ctx.ptr[type]
        x = x >? 0 <? ctx.w
        y = y >? 0 <? ctx.h
        ptr.style.top = "#{y}px"
        #@inputhex.value = @getValue!
        if type == 2 => ptr.style.left = "#{x}px"
        if !no-recurse and type == 1 =>
          ly = y * 1.04 - ctx.h * 0.02
          ly = (ly / ctx.h) >? 0 <? 1
          @set-alpha parseInt(1000 * (1 - ly)) / 1000
          @update-color @idx
        if !no-recurse and type != 1 =>
          [lx, ly] = [x * 1.04 - ctx.w * 0.02, y * 1.04 - ctx.h * 0.02]
          lx = (lx / ctx.w) >? 0 <? 1
          ly = (ly / ctx.h) >? 0 <? 1
          c = @color.vals[@idx]

          lit-v = if type == 2 => 1 - ly else ( 2 * c.lit + c.sat * ( 1 - Math.abs( 2 * c.lit - 1 ) ) ) / 2
          sat-v = if type == 2 => lx else 2 * ( lit-v - c.lit ) / lit-v
          hue = if type == 0 => ly * 360 else c.hue

          lit = lit-v * ( 2 - sat-v ) / 2
          sat = if lit != 0 and lit != 1 => lit-v * sat-v / ( 1 - Math.abs( 2 * lit - 1 ) ) else c.sat

          @set-hsl hue, sat, lit, false
          @update-color @idx

      move: (e, type, isClick = false) ->
        if !e.buttons and !isClick => return
        rect = @node.getBoundingClientRect!
        [y, x] = [e.clientY - rect.top, e.clientX - rect.left]
        @set-pos type, x - 5, y - 5

        if e.stopPropagation => e.stopPropagation!
        if e.preventDefault => e.preventDefault!
        e.cancelBubble = true
        e.returnValue = false
        false

      palette: []

  ldColorPicker.base64 = do
    hue: "data:image/png;base64,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"
    gradient: "data:image/png;base64,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"

  if $? =>
    $.fn.ldColorPicker = (config = {}) ->
      if !@.0 => return
      if @.0._ldcpnode => return @.0._ldcpnode._ldcp
      new ldColorPicker @.0, config

  if window? => window.ldColorPicker = ldColorPicker
  if angular? =>
    angular.module \ldColorPicker, <[]>
      ..directive \ldcolorpicker, -> do
        require: <[]>
        restrict: \A
        scope: ldcp: \=ngLdcp, color: \=ngModel, idx: \=ngIdx
        link: (s,e,a,c) ->
          s.ldcp = ldcp = new ldColorPicker e.0, {}, null
          ldcp.on \change, (color) -> s.$apply ->
            s.color = color
          ldcp.on \change-idx, (idx)-> s.$apply ->
            if a.ngIdx => s.idx = idx
          if a.ngIdx => s.idx = ldcp.getIdx!
