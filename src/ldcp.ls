# palette format:
# { name: "palette-name", colors: [C, C, ...] }
# color format "C": follow ldcolor ( { r,g,b,a,h,s,l,c,@l,@a,@b } )

(->
  cancel = (e) -> e.stopPropagation!; e.preventDefault!
  mouse = do
    over: false # is mousedown from ldcp? if true, document.click should not trigger toggle.
    start: (ldcp, type) ->
      list =
        * \selectstart, (e) -> cancel e
        * \mousemove, (e) -> mouse.move ldcp, e, type
        * \mouseup, (e) ->
            # after click event so document.click won't toggle ldcp off
            setTimeout (-> mouse.over = false), 100
            list.map -> document.removeEventListener it.0, it.1
            #setTimeout (-> if ldcp.d => document.addEventListener \click, target.clickToggler), 0
      list.map -> document.addEventListener it.0, it.1
      mouse.over = true
      #if target.clickToggler => document.removeEventListener \click, target.clickToggler
    move: (ldcp, e, type, is-click = false) ->
      if !(e.buttons or is-click) => return
      ldcp.set-pos type, e.clientX, e.clientY, true
      cancel e

  CLS = (node = null, cfg = {}) ->
    if typeof(node) == \string => node = document.querySelector(node)

    # Configuration initialization
    cfg = {
      className: ""
      context: \default
      onColorChange: null
      onPaletteChange: null
      idx: 0
      palette: null
      pinned: false
      exclusive: false
      inline: null
    } <<< cfg
    if node => for k,v of cfg => if (v = node.getAttribute("data-#{k.toLowerCase!}")) =>
      if k in <[onColorChange onPaletteChange]> => cfg[k] = new Function("color",v)
      else cfg[k] = v
    if cfg.context == \random => cfg.context = "random-#{Math.random!toString 16}"
    cfg.idx = if isNaN(+cfg.idx) => 0 else + +cfg.idx
    cfg.className = (cfg.className + " ldcolorpicker " + (if cfg.inline => [] else \bubble)).split(' ').filter(->it)
    #<[color palette]>.map(->"on#{it}change").map (name) ->
    #  if typeof(cfg[name]) == \string => cfg[name] = new Function [name], cfg[name]

    # Palette Initialization
    pal = cfg.palette
    pal = if typeof(pal) == \string =>
      pal = pal.trim!
      if pal.0 == \[ => colors: JSON.parse(pal).map -> ldcolor.hsl it
      else colors: pal.split(/[, ]/).map -> ldcolor.hsl it.trim!
    else if Array.isArray pal => colors: pal.map -> ldcolor.hsl it
    else pal

    # Object Initialization
    @ <<< {evt-handler: {}, dim: {d1: {}, d2: {}}} <<< cfg{idx, pinned, context, exclusive, inline}
    # toggler: element triggers this picker
    # root:    picker widget root element
    if cfg.inline => @ <<< toggler: null, root: node
    else
      @ <<< toggler: node, root: document.createElement \div
      #document.body.appendChild(@root)
    # Prepare Root Element
    @root
      ..style <<< position: \absolute, display: \none if !cfg.inline
      ..classList.add.apply @root.classList, cfg.className
      ..innerHTML = html
      ..getColorPicker = ~> @
      ..addEventListener \click, (e) -> cancel e

    # Locate DOM Elements
    @elem = elem = do
      mask0: ".ldcp-hue .ldcp-mask"
      ptr0:  ".ldcp-hue .ldcp-ptr-bar"
      panel0: ".ldcp-hue img"
      mask1: ".ldcp-alpha .ldcp-mask"
      ptr1:  ".ldcp-alpha .ldcp-ptr-bar"
      panel1: ".ldcp-alpha .ldcp-alpha-img"
      mask2: ".ldcp-2d .ldcp-mask"
      ptr2:  ".ldcp-2d .ldcp-ptr-circle"
      panel2: ".ldcp-2d img"
      d2: ".ldcp-2d"
      d1: ".ldcp-1d"
      btn-add: ".ldcp-cbtn:nth-of-type(1)"
      btn-del: ".ldcp-cbtn:nth-of-type(2)"
      caret: ".ldcp-caret"
      edit-group: ".ldcp-edit-group"
      color-none: ".ldcp-color-none"
      idx: ".ldcp-idx"
      pal: ".ldcp-palette"
    <[h s l r g b a hex]>.map -> elem["in-#it"] = ".ldcp-in-#it"
    for k,v of elem => elem[k] = @root.querySelector v
    @elem.comment = document.createComment " ldcolorpicker placeholder "
    if @root.parentNode => @root.parentNode.insertBefore @elem.comment, @root
    else document.body.appendChild @elem.comment
    if !@inline and @root.parentNode => @root.parentNode.removeChild @root


    # DOM Elements Config and Dynamics
    @elem.btn-add.addEventListener \click, (e) ~> @add-color!
    @elem.btn-del.addEventListener \click, (e) ~> @del-color!
    @elem.color-none.addEventListener \click, (e) ~> @set-alpha NaN
    @elem.pal.addEventListener \click, (e) ~>
      node = if e.target.classList.contains \ldcp-color => e.target else e.target.parentNode
      idx = Array.from(@elem.pal.querySelectorAll \.ldcp-color).indexOf(node)
      if idx >= 0 => @set-idx idx

    CLS.PalPool.bind cfg.context, @, pal # now we have @palette shared from PalPool
    @sync-palette!

    if @toggler => @toggler
      ..getColorPicker = ~> @
      ..addEventListener \click, (e) ~>
        setTimeout (~> @toggle!), 0
        if !cfg.exclusive or @root.style.display != \none => cancel e
      ..addEventListener \keyup (e) ~>
        ret = ldcolor.hsl(@toggler.value)
        if !isNaN(ret.h) => @setColor ret
      ..value = ldcolor.web(@get-color!)
      ..setAttribute \autocomplete, \off if @toggler.nodeName == \INPUT

    for n in <[mask ptr]> => for v from 0 to 2 => ((n,v) ~>
      elem["#n#v"]
        ..addEventListener \mousedown, (e) ~> mouse.start @, v
        ..addEventListener \click, (e) ~> mouse.move @, e, v, true
      ) n, v

    if cfg.onColorChange => @on \change, ~> cfg.onColorChange.apply @toggler, [it]
    if cfg.onPaletteChange => @on \change-palette, ~> cfg.onPaletteChange.apply @toggler, [it]

    # Final Initialization
    @set-idx @idx
    if cfg.pinned => @toggle true

    @fire \inited
    #@fire \change, #TBD, \inited
    #@fire \change-palette, #TBD, \inited

    @

  # PalPool Preparation
  (->
    pool = do
      # private
      update: (ldcp, ctx) -> ldcp.bind-palette @prepare(ctx).palette
      populate: (ctx) -> @prepare(ctx).users.map -> it.sync-palette ctx
      prepare: (ctx) -> if @hash[ctx] => that else @hash[ctx] = {users: [], palette: @random!}

      # public
      set: (ctx, pal) ->
        ctx = @prepare(ctx)
        # oldpal keep here for pickers to compare
        # and check if their active color is changed and should fire change event.
        ctx.oldpal = JSON.parse(JSON.stringify(ctx.palette{name, colors}))
        ctx.palette <<< JSON.parse(JSON.stringify pal{name, colors}); @populate ctx
      get: (ctx) -> return if @hash[ctx] => that.palette else null
      bind: (ctx, ldcp, pal) ->
        @prepare(ctx).users.push(ldcp)
        @update ldcp, ctx
        if pal? => @set ctx, pal

      # aux func. should be moved to ldPalette
      random: (n = 5) -> do
        name: 'Random'
        colors: [{h: Math.floor(Math.random! * 360), s: Math.random!, l: Math.random!} for i from 0 til n]

    pool.hash = {default: users: [], palette: pool.random!}
    CLS.PalPool = pool
  )!

  CLS.prototype = Object.create(Object.prototype) <<< do
    update-dimension: -> <[d1 d2]>.map ~>
      @dim[it] <<< {w: @elem[it]offsetWidth, h: @elem[it]offsetHeight}
    set-pos: (type, x, y, is-event = false) ->
      if !@dim.d1.w => @update-dimension!
      if typeof(type) != \number =>
        {h,s,l} = ldcolor.hsl(type)
        if !h => h = 0
        lv = ( 2 * l + s * ( 1 - Math.abs( 2 * l - 1 ) ) ) / 2
        sv = 2 * ( lv - l ) / lv
        if isNaN(sv) => sv = s
        x = ( @dim.d2.w * (sv) )
        y1 = ( @dim.d2.h * (1 - lv) ) / 1.00
        y2 = ( @dim.d1.h * (h / 360 ) ) / 1.00
        @elem.panel2.style.backgroundColor = ldcolor.web({h, s: 1, l: 0.5})
        @set-pos 2, x, y1, false
        @set-pos 0, x, y2, false
        @sync-color-at @idx
        return
      if is-event =>
        ret = @root.getBoundingClientRect!
        [x, y] = [x - ret.left - 5, y - ret.top - 5]
      {w,h} = @dim[if type == 2 => "d2" else "d1"]
      ptr = @elem["ptr#type"]
      x = x >? 0 <? w
      y = y >? 0 <? h
      ptr.style.top = "#{y}px"
      @elem["in-hex"].value = "#000" #@getHexString! TBD
      if type == 2 => ptr.style.left = "#{x}px"
      if !is-event => return
      if type == 1 => return @set-alpha +(1 - (((y * 1.04 - h * 0.02) / h) >? 0 <? 1)).toFixed(3)
      [lx, ly] = [x * 1.04 - w * 0.02, y * 1.04 - h * 0.02]
      [lx, ly] = [((lx / w) >? 0 <? 1), ((ly / h) >? 0 <? 1)]
      c = @get-color-at @idx, \hsl
      lv = if type == 2 => 1 - ly else ( 2 * c.l + c.s * ( 1 - Math.abs( 2 * c.l - 1 ) ) ) / 2
      sv = if type == 2 => lx else 2 * ( lv - c.l ) / lv
      h = if type == 0 => ly * 360 else c.h
      if !h => h = 0
      l = lv * ( 2 - sv ) / 2
      s = if l != 0 and l != 1 => lv * sv / ( 1 - Math.abs( 2 * l - 1 ) ) else x / w
      if isNaN(s) => s = 0
      if isNaN(l) => l = 0
      @set-color {h, s, l, a: c.a}

    set-idx: (ci, o = {}) ->
      if ci + 1 >= @elem.pal.childNodes.length => ci = @elem.pal.childNodes.length - 2
      oi = @idx
      @idx = ci
      n = @elem.pal.childNodes[ci + 1]
      @elem.idx.style.left = "#{n.offsetLeft + n.offsetWidth / 2}px"
      if @idx != oi => @fire \change-idx, ci, oi
      cc = @get-color-at ci, \hsl
      oc = @get-color-at oi, \hsl
      if !ldcolor.same(cc,oc) => @fire \change, cc, oc
      hsl = ldcolor.hsl(cc)
      if @toggler and !o.skip-input =>
        @toggler.setAttribute \data-idx, ci
        @toggler.value = ldcolor.web cc, ((@toggler.value or '').length  == 4)
      @set-pos hsl
    get-idx: -> @idx
    # update UI with possibly color change
    sync-color-at: (idx,n) ->
      n = (n or Array.from(@elem.pal.querySelectorAll \.ldcp-color)[idx])
      if !n => return
      n = n.childNodes.0
      c = ldcolor.hsl(@palette.colors[idx])
      if !c => return
      n.style.backgroundColor = ldcolor.web(c)
      n.classList[if isNaN(c.a) => "add" else "remove"] \none

    # update UI with possibly palette changes
    # if ctx is provided, there may be palette changes and should check for value changes.
    sync-palette: (ctx) ->
      pnode = @elem.pal
      nodes = pnode.querySelectorAll \.ldcp-color
      for i from 0 til Math.max(nodes.length, @palette.colors.length) =>
        if i >= nodes.length =>
          node = document.createElement \div
          node.classList.add \ldcp-color
          node.appendChild document.createElement \div
          pnode.appendChild node
        else if i >= @palette.colors.length => pnode.removeChild pnode.childNodes[pnode.childNodes.length - 1]
        if i < @palette.colors.length => @sync-color-at i, node
      if @idx >= @palette.colors.length => @idx = @palette.colors.length - 1

      oc = if ctx => (ctx.{}oldpal.colors or [])[@idx] else @get-color!
      if (context?) and context == @context and (affect-idx?) and (direction?) and affect-idx <= @idx =>
        @idx += direction
        @idx = @idx >? 0 <? @color.vals.length - 1
        if old-idx != @idx => @fire \change-idx, @idx
      @set-idx @idx

      if !ldcolor.same(cc = @get-color!, oc) => @fire \change, cc, oc
      #input?
      #if changed => @handle \change, value
      #if changed or direction => @handle \change-palette, @get-palette!

    # replace root palette object with this one.
    bind-palette: (pal) -> @palette = pal
    set-palette: (pal) -> CLS.PalPool.set @context, pal
    get-palette: -> @palette
    set-color: (cc) ->
      oc = @palette.colors[@idx]
      @palette.colors[@idx] = ldcolor.hsl cc
      @set-pos cc
      if !ldcolor.same(cc,oc) => @fire \change, cc, oc
      if @toggler => @toggler.value = ldcolor.web(cc, ((@toggler.value or '').length  == 4))
      CLS.PalPool.populate @context
    get-color: (type=\rgb) -> @get-color-at @idx, type
    get-color-at: (idx,type=\rgb) ->
      ret = ldcolor[type](@palette.colors[idx])
      # always clone object to prevent modification of inner object directly.
      if typeof(ret) == \object => ret = {} <<< ret
      return ret
    set-alpha: (a) ->
      oc = @get-color-at @idx
      @palette.colors[@idx].a = a
      cc = @get-color-at @idx
      if oc.a != a => @fire \change, cc, oc
      if @toggler => @toggler.value = ldcolor.web(cc, ((@toggler.value or '').length  == 4))
      @sync-color-at @idx
    get-alpha: -> @get-color-at(@idx, \rgb).a
    set-pin: (p) ->
      if @pinned != !!p => @fire \change-pin, p, @pinned
      @pinned = !!p
      if @pinned => @toggle true
    is-pinned: -> @pinned
    add-color: ->
      @palette.colors.splice @idx, 0, ldcolor.rand!
      @sync-palette!
    del-color: ->
      if @palette.colors.length > 1 => @palette.colors.splice @idx, 1
      @sync-palette!

    toggle: (is-on, toggler) ->
      if @pinned => is-on = true
      display = @root.style.display
      if ((is-on? and !is-on) or (!(is-on?) and display != \none)) and !@inline =>
        @root.style.display = \none
        if !@inline => @root.parentNode.removeChild @root
        document.removeEventListener \click, @doc-toggler
        document.removeEventListener \keydown, @key-toggler
        return @fire \toggle, false
      @root.style.display = \block
      if !@inline => @elem.comment.parentNode.insertBefore @root, @elem.comment
      toggler = @toggler or toggler
      if toggler =>
        if window.getComputedStyle(@root).position == \fixed => [sx,sy] = [0,0]
        else
          sx = window.pageXOffset or document.documentElement.scrollLeft or document.body.scrollLeft or 0
          sy = window.pageYOffset or document.documentElement.scrollTop or document.body.scrollTop or 0
        box = toggler.getBoundingClientRect!
        rbox = @root.getBoundingClientRect!
        [type, left, top, right, bottom] = [
          \bottom,
          box.left + sx, box.top + sy,
          box.left + box.width + sx, box.top + box.height + sy
        ]
        pos =
          top: box.top - @root.offsetHeight - 10 + sy
          left: box.left - @root.offsetWidth - 10 + sx
          right: box.left + toggler.offsetWidth + 10 + sx
          bottom: box.top + box.height + 10 + sy

        cls = {on: [], off: []}
        style = {}
        auto = if @root.classList.contains \vertical => \vertical
        else if @root.classList.contains \horizontal => \horizontal
        else null
        if auto == \vertical =>
          if pos.bottom + rbox.height - sy > window.innerHeight =>
            style.top = "#{pos.top}px"
            cls.on.push \top
            type = \top
          else
            style.top = "#{pos.bottom}px"
            cls.off.push \top
            type = \bottom
        else if auto == \horizontal =>
          if pos.right + rbox.width - sx > window.innerWidth =>
            style.left = "#{pos.left}px"
            cls.on.push \left
            cls.off.push \right
            type = \left
          else
            style.left = "#{pos.right}px"
            cls.on.push \right
            cls.off.push \left
            type = \right
        else
          # without setting type here, picker may be placed in unexpected position
          # because positional style not updated below.
          if @root.classList.contains \top => style.top = "#{pos.top}px"; type = \top
          else if @root.classList.contains \left => style.left = "#{pos.left}px"; type = \left
          else if @root.classList.contains \right => style.left = "#{pos.right}px"; type = \right
          else style.top = "#{pos.bottom}px"; type = \bottom

        if type in <[bottom top]> =>
          if left + rbox.width - sx >= window.innerWidth =>
            style.left = "#{right - rbox.width}px"
            cls.on.push 'right-align'
          else
            style.left = "#{left}px"
            cls.off.push 'right-align'
        if type in <[right left]> =>
          if top + rbox.height - sy >= window.innerHeight =>
            style.top = "#{bottom - rbox.height}px"
            cls.on.push 'bottom-align'
          else
            style.top = "#{top}px"
            cls.off.push 'bottom-align'

        @root.style <<< style
        cls.on.map ~> @root.classList.toggle it, true
        cls.off.map ~> @root.classList.toggle it, false
        # TODO simplify boundary check logic, if possible

      if !@inline =>
        document.addEventListener \keydown, (~>
          document.removeEventListener \keydown, @key-toggler
          @key-toggler = (e) ~>
            if (e.which or e.keyCode) == 27 and @toggler and !@pinned => @toggle false
        )!
        document.addEventListener \click, (~>
          document.removeEventListener \click, @doc-toggler
          @doc-toggler = ~>
            if mouse.over => return mouse.over = false
            document.removeEventListener \click, @doc-toggler
            @toggle!
        )!

      @update-dimension!
      #if @target =>
      #  ret = @color.vals.map((it,idx) ~> [idx, @toValue(it)]).filter(~> it.1 == @target.value.to-lower-case!).0
      #  if ret => @idx = ret.0
      #  else @color.vals.splice 0, 0, @convert.color @target.value
      @set-idx @idx, {skip-input: true}
      @fire \toggle, true


    on: (n, cb) -> @evt-handler.[][n].push cb
    fire: (n, ...v) -> for cb in (@evt-handler[n] or []) => cb.apply @, v
    destroy: ->
      @root.parentNode.removeChild @root
      @evt-handler = {}

  if module? => module.exports = CLS
  else window.ldcolorpicker = CLS
)!

/*
use classList, need https://github.com/eligrey/classList.js polyfill for IE 8 ~ 11
target -> node
node -> <removed>
custom-callback -> cfg.oncolorchange
custom-pal-callback -> cfg.onpalettechange
custom-palette-idx -> cfg.idx
custom-* -> cfg.*
cpclass, class -> className
@initpal -> @pal
 --> add "inline" config: is the provided element a container(inline), or a trigger?(btn)
*/

images =
  hue: "data:image/jpg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAYEBAUEBAYFBQUGBgYHCQ4JCQgICRINDQoOFRIWFhUSFBQXGiEcFxgfGRQUHScdHyIjJSUlFhwpLCgkKyEkJST/2wBDAQYGBgkICREJCREkGBQYJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCT/wgARCADIABQDAREAAhEBAxEB/8QAGwABAAIDAQEAAAAAAAAAAAAAAAECAwQFBgf/xAAbAQEAAgMBAQAAAAAAAAAAAAAAAQYDBAUCB//aAAwDAQACEAMQAAAA85W/sMFjqaepBY9vX+GJPcV7lCTrczkAcXbrYGPJhAAAAzdXGEtmzYANyz4AM1jwTJDxVj9CT51ZvYtD5/ZMUGXx6wZc0QubWHpC0T19OwiYdzQsYk39XfSmGjy9oScut7sFkc2s7ok1uRlgsf/EACcQAAEDAgYCAQUAAAAAAAAAAAABAhMUFQMEBSFhYhBSEhEiMEFR/9oACAEBAAE/APDSz8Fn4G6PwWfqWbqJo/Us3BZ+omj9StK0rSZxO4nd+KMjIyIiIiIiIibA90JsH3QmwfdC+di+9hNd7l93X7y+9xmtq5NnFdmPqu/7K7Mf0wdSzLEXlT47qfEY3ZSm3UphmW2UoyjG5PgouCh4G5LjxsIVJUjcyTk43HJicbjeWn//xAAfEQEBAAEFAAMBAAAAAAAAAAAAFBMBAhESYQMQIDD/2gAIAQIBAT8A+6VKlSpUqVKlw4cOmjpo6afykSJEfiPxH4kSJGDROn8SJEiRIkYdjFtbvh2ffLu7u7IyMjKysv4qVKlSpUrWeq/x/8QAHhEBAAICAwEBAQAAAAAAAAAAABIUAhMRIGEBEDD/2gAIAQMBAT8A/bCwst7e3tra2rS0tN+Tfk35fykkkkkkkkl04cOOnOTnJ8+5IooqysrKvir4q+Kvir4q9NbW1NbWgggh0//Z"
  gradient: "data:image/png;base64,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"
  opacity: "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAACACAYAAAAClekiAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAA1ZJREFUeNrcWVuO3EAIBNz5zxXmP/c/Qc4x85VbRCKezXrUxlSBxytFir+86x6a5lEFtN7v928i4vL30fAut9vNt/fp2+sZ0+LtxxYWW3g/CEALNoE6aSBRkwEWzD9m/9cR1J/PauDcFjWw2Wjg3dH3EXbKrK3sW/SCJO6UsInNAtXdv4MdP94fj4dn8bEJGcC/2Xnno7yM/BSwhLNp8jf00Ag7VFoc3kfyQ2Fnjv/fjoCSif0NQ1kTg6GjCQplSeIj+y5j9fMi+PEVD2IOzEJ8oLMRO+wMu+WCsmgk9jCWjQ6icbdmZDAFQjhdwwQIc1+GB9WTuxEIOLgLbfTEgx9s2zVOqDZnjiBdGzCrlwIQhUGhg7BRJ6w9wwMBoasJtekADGTMdfP6rhccEKw+8YB6YcUDlqmSpXNmB8SVjnjBEztkG9gACy3Rwq5mI4zEpYg+ZbRXpTMsrpgXKlTaM9Pq54UhzlQfZMCyY2cjiQQjdHwew5vsfPg+ws6l36OBvzQOBGjCYkPHm8Y7aFAZTFAVs+EBSt25X3CUzpdhfUncZB04e8eNmjUcS8NwkOKrAqPCA9hweNEn2BxISxZhXU9seJAlj0/9Aiy8uuwsjFgW4gGtkiwT0Nl5hwf6JibsvCCNztVRv7AQPKB5UDFTKzojHkiCB1JpYCdKfJqN8g42omzULkLP5MrO6oiAUBx00aktAKJ2FkjeRKcXHiib1Kxxwqo2vWKDEpUZRpziBRpcUQM9Ua0oqpEMUF0GcYdc0GKmlNZICyi0EdHuYT3pF3YaJHhwqtguxwLMC8qQKhZZXd+nyWSktCmpLh7BCKCk2cnGQF7EhV1FpA9hz/nBTwYgU31wuv3XznSnU+qyIQwdA3U6eMumeR12gul8KRK/bAhzTkDAg0M+BDxISxzrzMzYSPQf2wDwYoetD6GsZKEwetds2Er6BNgzoYsYk/ya5IUHv4DKbJ646xf0RAy03OiNnkEydo4XUw4AV9lcmV1KpLxRRSIbwEhmRJY4yhrPynBQ8PisAxVVYqA+OFBb5gUlJe7unslIIJVXSOyeqWq6WuzMRgNlNmpRbAoahSGiVVQrdwbRmuCBb/cLv9mshODBKVCFhDuaIKKVBm8/l0jlPxHwR4ABAF3bekgydK22AAAAAElFTkSuQmCC"

#  opacity: "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAACACAYAAADK+QP0AAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAOtJREFUeNqEUcuKhEAMTFdaBQUZv8P/2W/eg1cPgoh4UBAFPXgQX9vqjK9p2ByKPKor6YSCIABI2Q7jOBI8zxO0LAsfBfGPlyQJoSxLAcMwHpQrTNMk4DjOJv/SUj6AS5hlmUCe5zjkcee9YZ5nAcuyQKqRj80eFB0URQGkacowTfMs8AHv3LYSZUx93/+s5AdF3t/KfciqqhhxHMt1eh1v84w9VF8AfN+XsG2b72OwtkfTNIwoihhSymvfj+jZktf7gtq2/YXruroxvnJd1zHCMJRgZYfy6cnLhoZhANV13a/3He57Jh38CTAAd4JShjUxxxYAAAAASUVORK5CYII="

html = """
<div class='ldcp-panel'><div class='ldcp-v ldcp-g1'><div class='ldcp-h ldcp-g11 ldcp-2d'><div style='top:20px;left:20px' class='ldcp-ptr-circle'></div><img src='#{images.gradient}'><div class='ldcp-mask'></div></div><div class='ldcp-h ldcp-g12 ldcp-1d ldcp-hue'><div class='ldcp-ptr-bar'></div><img src='#{images.hue}'><div class='ldcp-mask'></div></div><div class='ldcp-h ldcp-g13 ldcp-1d ldcp-alpha'><div class='ldcp-ptr-bar'></div><div class='ldcp-alpha-img' style='background-image:url(#{images.opacity})'></div><div class='ldcp-mask'></div></div></div><div class='ldcp-v ldcp-g2'><div class='ldcp-colors ldcp-h ldcp-g21'><div class='ldcp-palette'><small class='ldcp-idx'></small></div><small class='ldcp-sep'></small><div class='ldcp-color-none'></div><span class='ldcp-cbtn ldcp-btn-add'>+</span><span class='ldcp-cbtn ldcp-btn-remove'>-</span></div></div>
<div class='ldcp-v ldcp-g3'><div class='ldcp-h ldcp-g31'>
<div class='ldcp-edit-group'><span>R</span><input class='ldcp-in-r' value='255'><span>G</span><input class='ldcp-in-g' value='255'><span>B</span><input class='ldcp-in-b' value='255'></div>
<div class='ldcp-edit-group' style='display:none'><span>H</span><input class='ldcp-in-h' value='255'><span>S</span><input class='ldcp-in-s' value='255'><span>L</span><input class='ldcp-in-l' value='255'></div>
<div class='ldcp-edit-group ldcp-edit-hex' style='display:none'><span>HEX</span><input class='ldcp-in-hex' value='#000000'></div>
<span>A</span><input value='255' class='ldcp-in-a'>
<span class='ldcp-caret'>RGBA &\#x25be;</span></div></div></div><div class='ldcp-chooser'><button/><button/><button/></div>
"""

