var images, html;
(function(){
  var cancel, mouse, CLS;
  cancel = function(e){
    e.stopPropagation();
    return e.preventDefault();
  };
  mouse = {
    over: false,
    start: function(ldcp, type){
      var list;
      list = [
        [
          'selectstart', function(e){
            return cancel(e);
          }
        ], [
          'mousemove', function(e){
            return mouse.move(ldcp, e, type);
          }
        ], [
          'mouseup', function(e){
            setTimeout(function(){
              return mouse.over = false;
            }, 100);
            return list.map(function(it){
              return document.removeEventListener(it[0], it[1]);
            });
          }
        ]
      ];
      list.map(function(it){
        return document.addEventListener(it[0], it[1]);
      });
      return mouse.over = true;
    },
    move: function(ldcp, e, type, isClick){
      isClick == null && (isClick = false);
      if (!(e.buttons || isClick)) {
        return;
      }
      ldcp.setPos(type, e.clientX, e.clientY, true);
      return cancel(e);
    }
  };
  CLS = function(node, cfg){
    var k, v, pal, ref$, x$, elem, y$, i$, len$, n, j$, this$ = this;
    node == null && (node = null);
    cfg == null && (cfg = {});
    if (typeof node === 'string') {
      node = document.querySelector(node);
    }
    cfg = import$({
      className: "",
      context: 'default',
      onColorChange: null,
      onPaletteChange: null,
      idx: 0,
      palette: null,
      pinned: false,
      exclusive: false,
      inline: null
    }, cfg);
    if (node) {
      for (k in cfg) {
        v = cfg[k];
        if (v = node.getAttribute("data-" + k.toLowerCase())) {
          if (k === 'onColorChange' || k === 'onPaletteChange') {
            cfg[k] = new Function("color", v);
          } else {
            cfg[k] = v;
          }
        }
      }
    }
    if (cfg.context === 'random') {
      cfg.context = "random-" + Math.random().toString(16);
    }
    cfg.idx = isNaN(+cfg.idx)
      ? 0
      : + +cfg.idx;
    cfg.className = (cfg.className + " ldcolorpicker " + (cfg.inline ? [] : 'bubble')).split(' ').filter(function(it){
      return it;
    });
    pal = cfg.palette;
    pal = typeof pal === 'string'
      ? (pal = pal.trim(), pal[0] === '['
        ? {
          colors: JSON.parse(pal).map(function(it){
            return ldcolor.hsl(it);
          })
        }
        : {
          colors: pal.split(/[, ]/).map(function(it){
            return ldcolor.hsl(it.trim());
          })
        })
      : Array.isArray(pal) ? {
        colors: pal.map(function(it){
          return ldcolor.hsl(it);
        })
      } : pal;
    ref$ = (this.evtHandler = {}, this.dim = {
      d1: {},
      d2: {}
    }, this);
    ref$.idx = cfg.idx;
    ref$.pinned = cfg.pinned;
    ref$.context = cfg.context;
    ref$.exclusive = cfg.exclusive;
    ref$.inline = cfg.inline;
    if (cfg.inline) {
      this.toggler = null;
      this.root = node;
    } else {
      this.toggler = node;
      this.root = document.createElement('div');
    }
    x$ = this.root;
    if (!cfg.inline) {
      ref$ = x$.style;
      ref$.position = 'absolute';
      ref$.display = 'none';
    }
    x$.classList.add.apply(this.root.classList, cfg.className);
    x$.innerHTML = html;
    x$.getColorPicker = function(){
      return this$;
    };
    x$.addEventListener('click', function(e){
      return cancel(e);
    });
    this.elem = elem = {
      mask0: ".ldcp-hue .ldcp-mask",
      ptr0: ".ldcp-hue .ldcp-ptr-bar",
      panel0: ".ldcp-hue img",
      mask1: ".ldcp-alpha .ldcp-mask",
      ptr1: ".ldcp-alpha .ldcp-ptr-bar",
      panel1: ".ldcp-alpha .ldcp-alpha-img",
      mask2: ".ldcp-2d .ldcp-mask",
      ptr2: ".ldcp-2d .ldcp-ptr-circle",
      panel2: ".ldcp-2d img",
      d2: ".ldcp-2d",
      d1: ".ldcp-1d",
      btnAdd: ".ldcp-cbtn:nth-of-type(1)",
      btnDel: ".ldcp-cbtn:nth-of-type(2)",
      caret: ".ldcp-caret",
      editGroup: ".ldcp-edit-group",
      colorNone: ".ldcp-color-none",
      idx: ".ldcp-idx",
      pal: ".ldcp-palette"
    };
    ['h', 's', 'l', 'r', 'g', 'b', 'a', 'hex'].map(function(it){
      return elem["in-" + it] = ".ldcp-in-" + it;
    });
    for (k in elem) {
      v = elem[k];
      elem[k] = this.root.querySelector(v);
    }
    this.elem.comment = document.createComment(" ldcolorpicker placeholder ");
    if (this.root.parentNode) {
      this.root.parentNode.insertBefore(this.elem.comment, this.root);
    } else {
      document.body.appendChild(this.elem.comment);
    }
    if (!this.inline && this.root.parentNode) {
      this.root.parentNode.removeChild(this.root);
    }
    this.elem.btnAdd.addEventListener('click', function(e){
      return this$.addColor();
    });
    this.elem.btnDel.addEventListener('click', function(e){
      return this$.delColor();
    });
    this.elem.colorNone.addEventListener('click', function(e){
      return this$.setAlpha(NaN);
    });
    this.elem.pal.addEventListener('click', function(e){
      var node, idx;
      node = e.target.classList.contains('ldcp-color')
        ? e.target
        : e.target.parentNode;
      idx = Array.from(this$.elem.pal.querySelectorAll('.ldcp-color')).indexOf(node);
      if (idx >= 0) {
        return this$.setIdx(idx);
      }
    });
    CLS.PalPool.bind(cfg.context, this, pal);
    this.syncPalette();
    if (this.toggler) {
      y$ = this.toggler;
      y$.getColorPicker = function(){
        return this$;
      };
      y$.addEventListener('click', function(e){
        setTimeout(function(){
          return this$.toggle();
        }, 0);
        if (!cfg.exclusive || this$.root.style.display !== 'none') {
          return cancel(e);
        }
      });
      y$.addEventListener('keyup', function(e){
        var ret;
        ret = ldcolor.hsl(this$.toggler.value);
        if (!isNaN(ret.h)) {
          return this$.setColor(ret);
        }
      });
      y$.value = ldcolor.web(this.getColor());
      if (this.toggler.nodeName === 'INPUT') {
        y$.setAttribute('autocomplete', 'off');
      }
    }
    for (i$ = 0, len$ = (ref$ = ['mask', 'ptr']).length; i$ < len$; ++i$) {
      n = ref$[i$];
      for (j$ = 0; j$ <= 2; ++j$) {
        v = j$;
        fn$(n, v);
      }
    }
    if (cfg.onColorChange) {
      this.on('change', function(it){
        return cfg.onColorChange.apply(this$.toggler, [it]);
      });
    }
    if (cfg.onPaletteChange) {
      this.on('change-palette', function(it){
        return cfg.onPaletteChange.apply(this$.toggler, [it]);
      });
    }
    this.setIdx(this.idx);
    if (cfg.pinned) {
      this.toggle(true);
    }
    this.fire('inited');
    return this;
    function fn$(n, v){
      var x$;
      x$ = elem[n + "" + v];
      x$.addEventListener('mousedown', function(e){
        return mouse.start(this$, v);
      });
      x$.addEventListener('click', function(e){
        return mouse.move(this$, e, v, true);
      });
      return x$;
    }
  };
  (function(){
    var pool;
    pool = {
      update: function(ldcp, ctx){
        return ldcp.bindPalette(this.prepare(ctx).palette);
      },
      populate: function(ctx){
        return this.prepare(ctx).users.map(function(it){
          return it.syncPalette(ctx);
        });
      },
      prepare: function(ctx){
        var that;
        if (that = this.hash[ctx]) {
          return that;
        } else {
          return this.hash[ctx] = {
            users: [],
            palette: this.random()
          };
        }
      },
      set: function(ctx, pal){
        var ref$;
        ctx = this.prepare(ctx);
        ctx.oldpal = JSON.parse(JSON.stringify({
          name: (ref$ = ctx.palette).name,
          colors: ref$.colors
        }));
        import$(ctx.palette, JSON.parse(JSON.stringify({
          name: pal.name,
          colors: pal.colors
        })));
        return this.populate(ctx);
      },
      get: function(ctx){
        var that;
        return (that = this.hash[ctx]) ? that.palette : null;
      },
      bind: function(ctx, ldcp, pal){
        this.prepare(ctx).users.push(ldcp);
        this.update(ldcp, ctx);
        if (pal != null) {
          return this.set(ctx, pal);
        }
      },
      random: function(n){
        var i;
        n == null && (n = 5);
        return {
          name: 'Random',
          colors: (function(){
            var i$, to$, results$ = [];
            for (i$ = 0, to$ = n; i$ < to$; ++i$) {
              i = i$;
              results$.push({
                h: Math.floor(Math.random() * 360),
                s: Math.random(),
                l: Math.random()
              });
            }
            return results$;
          }())
        };
      }
    };
    pool.hash = {
      'default': {
        users: [],
        palette: pool.random()
      }
    };
    return CLS.PalPool = pool;
  })();
  CLS.prototype = import$(Object.create(Object.prototype), {
    updateDimension: function(){
      var this$ = this;
      return ['d1', 'd2'].map(function(it){
        var ref$;
        return ref$ = this$.dim[it], ref$.w = this$.elem[it].offsetWidth, ref$.h = this$.elem[it].offsetHeight, ref$;
      });
    },
    setPos: function(type, x, y, isEvent){
      var ref$, h, s, l, lv, sv, y1, y2, ret, w, ptr, ref1$, lx, ly, c;
      isEvent == null && (isEvent = false);
      if (!this.dim.d1.w) {
        this.updateDimension();
      }
      if (typeof type !== 'number') {
        ref$ = ldcolor.hsl(type), h = ref$.h, s = ref$.s, l = ref$.l;
        if (!h) {
          h = 0;
        }
        lv = (2 * l + s * (1 - Math.abs(2 * l - 1))) / 2;
        sv = 2 * (lv - l) / lv;
        if (isNaN(sv)) {
          sv = s;
        }
        x = this.dim.d2.w * sv;
        y1 = (this.dim.d2.h * (1 - lv)) / 1.00;
        y2 = (this.dim.d1.h * (h / 360)) / 1.00;
        this.elem.panel2.style.backgroundColor = ldcolor.web({
          h: h,
          s: 1,
          l: 0.5
        });
        this.setPos(2, x, y1, false);
        this.setPos(0, x, y2, false);
        this.syncColorAt(this.idx);
        return;
      }
      if (isEvent) {
        ret = this.root.getBoundingClientRect();
        ref$ = [x - ret.left - 5, y - ret.top - 5], x = ref$[0], y = ref$[1];
      }
      ref$ = this.dim[type === 2 ? "d2" : "d1"], w = ref$.w, h = ref$.h;
      ptr = this.elem["ptr" + type];
      x = (ref$ = x > 0 ? x : 0) < w ? ref$ : w;
      y = (ref$ = y > 0 ? y : 0) < h ? ref$ : h;
      ptr.style.top = y + "px";
      this.elem["in-hex"].value = "#000";
      if (type === 2) {
        ptr.style.left = x + "px";
      }
      if (!isEvent) {
        return;
      }
      if (type === 1) {
        return this.setAlpha(+(1 - ((ref$ = (ref1$ = (y * 1.04 - h * 0.02) / h) > 0 ? ref1$ : 0) < 1 ? ref$ : 1)).toFixed(3));
      }
      ref$ = [x * 1.04 - w * 0.02, y * 1.04 - h * 0.02], lx = ref$[0], ly = ref$[1];
      ref$ = [(ref$ = (ref1$ = lx / w) > 0 ? ref1$ : 0) < 1 ? ref$ : 1, (ref$ = (ref1$ = ly / h) > 0 ? ref1$ : 0) < 1 ? ref$ : 1], lx = ref$[0], ly = ref$[1];
      c = this.getColorAt(this.idx, 'hsl');
      lv = type === 2
        ? 1 - ly
        : (2 * c.l + c.s * (1 - Math.abs(2 * c.l - 1))) / 2;
      sv = type === 2
        ? lx
        : 2 * (lv - c.l) / lv;
      h = type === 0
        ? ly * 360
        : c.h;
      if (!h) {
        h = 0;
      }
      l = lv * (2 - sv) / 2;
      s = l !== 0 && l !== 1
        ? lv * sv / (1 - Math.abs(2 * l - 1))
        : x / w;
      if (isNaN(s)) {
        s = 0;
      }
      if (isNaN(l)) {
        l = 0;
      }
      return this.setColor({
        h: h,
        s: s,
        l: l,
        a: c.a
      });
    },
    setIdx: function(ci, o){
      var oi, n, cc, oc, hsl;
      o == null && (o = {});
      if (ci + 1 >= this.elem.pal.childNodes.length) {
        ci = this.elem.pal.childNodes.length - 2;
      }
      oi = this.idx;
      this.idx = ci;
      n = this.elem.pal.childNodes[ci + 1];
      this.elem.idx.style.left = (n.offsetLeft + n.offsetWidth / 2) + "px";
      if (this.idx !== oi) {
        this.fire('change-idx', ci, oi);
      }
      cc = this.getColorAt(ci, 'hsl');
      oc = this.getColorAt(oi, 'hsl');
      if (!ldcolor.same(cc, oc)) {
        this.fire('change', cc, oc);
      }
      hsl = ldcolor.hsl(cc);
      if (this.toggler && !o.skipInput) {
        this.toggler.setAttribute('data-idx', ci);
        this.toggler.value = ldcolor.web(cc, (this.toggler.value || '').length === 4);
      }
      return this.setPos(hsl);
    },
    getIdx: function(){
      return this.idx;
    },
    syncColorAt: function(idx, n){
      var c;
      n = n || Array.from(this.elem.pal.querySelectorAll('.ldcp-color'))[idx];
      if (!n) {
        return;
      }
      n = n.childNodes[0];
      c = ldcolor.hsl(this.palette.colors[idx]);
      if (!c) {
        return;
      }
      n.style.backgroundColor = ldcolor.web(c);
      return n.classList[isNaN(c.a) ? "add" : "remove"]('none');
    },
    syncPalette: function(ctx){
      var pnode, nodes, i$, to$, i, node, oc, ref$, ref1$, ref2$, cc;
      pnode = this.elem.pal;
      nodes = pnode.querySelectorAll('.ldcp-color');
      for (i$ = 0, to$ = Math.max(nodes.length, this.palette.colors.length); i$ < to$; ++i$) {
        i = i$;
        if (i >= nodes.length) {
          node = document.createElement('div');
          node.classList.add('ldcp-color');
          node.appendChild(document.createElement('div'));
          pnode.appendChild(node);
        } else if (i >= this.palette.colors.length) {
          pnode.removeChild(pnode.childNodes[pnode.childNodes.length - 1]);
        }
        if (i < this.palette.colors.length) {
          this.syncColorAt(i, node);
        }
      }
      if (this.idx >= this.palette.colors.length) {
        this.idx = this.palette.colors.length - 1;
      }
      oc = ctx
        ? ((ctx.oldpal || (ctx.oldpal = {})).colors || [])[this.idx]
        : this.getColor();
      if ((typeof context != 'undefined' && context !== null) && context === this.context && (typeof affectIdx != 'undefined' && affectIdx !== null) && (typeof direction != 'undefined' && direction !== null) && affectIdx <= this.idx) {
        this.idx += direction;
        this.idx = (ref$ = (ref2$ = this.idx) > 0 ? ref2$ : 0) < (ref1$ = this.color.vals.length - 1) ? ref$ : ref1$;
        if (oldIdx !== this.idx) {
          this.fire('change-idx', this.idx);
        }
      }
      this.setIdx(this.idx);
      if (!ldcolor.same(cc = this.getColor(), oc)) {
        return this.fire('change', cc, oc);
      }
    },
    bindPalette: function(pal){
      return this.palette = pal;
    },
    setPalette: function(pal){
      return CLS.PalPool.set(this.context, pal);
    },
    getPalette: function(){
      return this.palette;
    },
    setColor: function(cc){
      var oc;
      oc = this.palette.colors[this.idx];
      this.palette.colors[this.idx] = ldcolor.hsl(cc);
      this.setPos(cc);
      if (!ldcolor.same(cc, oc)) {
        this.fire('change', cc, oc);
      }
      if (this.toggler) {
        this.toggler.value = ldcolor.web(cc, (this.toggler.value || '').length === 4);
      }
      return CLS.PalPool.populate(this.context);
    },
    getColor: function(type){
      type == null && (type = 'rgb');
      return this.getColorAt(this.idx, type);
    },
    getColorAt: function(idx, type){
      var ret;
      type == null && (type = 'rgb');
      ret = ldcolor[type](this.palette.colors[idx]);
      if (typeof ret === 'object') {
        ret = import$({}, ret);
      }
      return ret;
    },
    setAlpha: function(a){
      var oc, cc;
      oc = this.getColorAt(this.idx);
      this.palette.colors[this.idx].a = a;
      cc = this.getColorAt(this.idx);
      if (oc.a !== a) {
        this.fire('change', cc, oc);
      }
      if (this.toggler) {
        this.toggler.value = ldcolor.web(cc, (this.toggler.value || '').length === 4);
      }
      return this.syncColorAt(this.idx);
    },
    getAlpha: function(){
      return this.getColorAt(this.idx, 'rgb').a;
    },
    setPin: function(p){
      if (this.pinned !== !!p) {
        this.fire('change-pin', p, this.pinned);
      }
      this.pinned = !!p;
      if (this.pinned) {
        return this.toggle(true);
      }
    },
    isPinned: function(){
      return this.pinned;
    },
    addColor: function(){
      this.palette.colors.splice(this.idx, 0, ldcolor.rand());
      return this.syncPalette();
    },
    delColor: function(){
      if (this.palette.colors.length > 1) {
        this.palette.colors.splice(this.idx, 1);
      }
      return this.syncPalette();
    },
    toggle: function(isOn, toggler){
      var display, ref$, sx, sy, box, rbox, type, left, top, right, bottom, pos, cls, style, auto, this$ = this;
      if (this.pinned) {
        isOn = true;
      }
      display = this.root.style.display;
      if (((isOn != null && !isOn) || (!(isOn != null) && display !== 'none')) && !this.inline) {
        this.root.style.display = 'none';
        if (!this.inline) {
          this.root.parentNode.removeChild(this.root);
        }
        document.removeEventListener('click', this.docToggler);
        document.removeEventListener('keydown', this.keyToggler);
        return this.fire('toggle', false);
      }
      this.root.style.display = 'block';
      if (!this.inline) {
        this.elem.comment.parentNode.insertBefore(this.root, this.elem.comment);
      }
      toggler = this.toggler || toggler;
      if (toggler) {
        if (window.getComputedStyle(this.root).position === 'fixed') {
          ref$ = [0, 0], sx = ref$[0], sy = ref$[1];
        } else {
          sx = window.pageXOffset || document.documentElement.scrollLeft || document.body.scrollLeft || 0;
          sy = window.pageYOffset || document.documentElement.scrollTop || document.body.scrollTop || 0;
        }
        box = toggler.getBoundingClientRect();
        rbox = this.root.getBoundingClientRect();
        ref$ = ['bottom', box.left + sx, box.top + sy, box.left + box.width + sx, box.top + box.height + sy], type = ref$[0], left = ref$[1], top = ref$[2], right = ref$[3], bottom = ref$[4];
        pos = {
          top: box.top - this.root.offsetHeight - 10 + sy,
          left: box.left - this.root.offsetWidth - 10 + sx,
          right: box.left + toggler.offsetWidth + 10 + sx,
          bottom: box.top + box.height + 10 + sy
        };
        cls = {
          on: [],
          off: []
        };
        style = {};
        auto = this.root.classList.contains('vertical')
          ? 'vertical'
          : this.root.classList.contains('horizontal') ? 'horizontal' : null;
        if (auto === 'vertical') {
          if (pos.bottom + rbox.height - sy > window.innerHeight) {
            style.top = pos.top + "px";
            cls.on.push('top');
            type = 'top';
          } else {
            style.top = pos.bottom + "px";
            cls.off.push('top');
            type = 'bottom';
          }
        } else if (auto === 'horizontal') {
          if (pos.right + rbox.width - sx > window.innerWidth) {
            style.left = pos.left + "px";
            cls.on.push('left');
            cls.off.push('right');
            type = 'left';
          } else {
            style.left = pos.right + "px";
            cls.on.push('right');
            cls.off.push('left');
            type = 'right';
          }
        } else {
          if (this.root.classList.contains('top')) {
            style.top = pos.top + "px";
            type = 'top';
          } else if (this.root.classList.contains('left')) {
            style.left = pos.left + "px";
            type = 'left';
          } else if (this.root.classList.contains('right')) {
            style.left = pos.right + "px";
            type = 'right';
          } else {
            style.top = pos.bottom + "px";
            type = 'bottom';
          }
        }
        if (type === 'bottom' || type === 'top') {
          if (left + rbox.width - sx >= window.innerWidth) {
            style.left = (right - rbox.width) + "px";
            cls.on.push('right-align');
          } else {
            style.left = left + "px";
            cls.off.push('right-align');
          }
        }
        if (type === 'right' || type === 'left') {
          if (top + rbox.height - sy >= window.innerHeight) {
            style.top = (bottom - rbox.height) + "px";
            cls.on.push('bottom-align');
          } else {
            style.top = top + "px";
            cls.off.push('bottom-align');
          }
        }
        import$(this.root.style, style);
        cls.on.map(function(it){
          return this$.root.classList.toggle(it, true);
        });
        cls.off.map(function(it){
          return this$.root.classList.toggle(it, false);
        });
      }
      if (!this.inline) {
        document.addEventListener('keydown', function(){
          document.removeEventListener('keydown', this$.keyToggler);
          return this$.keyToggler = function(e){
            if ((e.which || e.keyCode) === 27 && this$.toggler && !this$.pinned) {
              return this$.toggle(false);
            }
          };
        }());
        document.addEventListener('click', function(){
          document.removeEventListener('click', this$.docToggler);
          return this$.docToggler = function(){
            if (mouse.over) {
              return mouse.over = false;
            }
            document.removeEventListener('click', this$.docToggler);
            return this$.toggle();
          };
        }());
      }
      this.updateDimension();
      this.setIdx(this.idx, {
        skipInput: true
      });
      return this.fire('toggle', true);
    },
    on: function(n, cb){
      var ref$;
      return ((ref$ = this.evtHandler)[n] || (ref$[n] = [])).push(cb);
    },
    fire: function(n){
      var v, res$, i$, to$, ref$, len$, cb, results$ = [];
      res$ = [];
      for (i$ = 1, to$ = arguments.length; i$ < to$; ++i$) {
        res$.push(arguments[i$]);
      }
      v = res$;
      for (i$ = 0, len$ = (ref$ = this.evtHandler[n] || []).length; i$ < len$; ++i$) {
        cb = ref$[i$];
        results$.push(cb.apply(this, v));
      }
      return results$;
    },
    destroy: function(){
      this.root.parentNode.removeChild(this.root);
      return this.evtHandler = {};
    }
  });
  if (typeof module != 'undefined' && module !== null) {
    return module.exports = CLS;
  } else {
    return window.ldcolorpicker = CLS;
  }
})();
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
images = {
  hue: "data:image/jpg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAYEBAUEBAYFBQUGBgYHCQ4JCQgICRINDQoOFRIWFhUSFBQXGiEcFxgfGRQUHScdHyIjJSUlFhwpLCgkKyEkJST/2wBDAQYGBgkICREJCREkGBQYJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCT/wgARCADIABQDAREAAhEBAxEB/8QAGwABAAIDAQEAAAAAAAAAAAAAAAECAwQFBgf/xAAbAQEAAgMBAQAAAAAAAAAAAAAAAQYDBAUCB//aAAwDAQACEAMQAAAA85W/sMFjqaepBY9vX+GJPcV7lCTrczkAcXbrYGPJhAAAAzdXGEtmzYANyz4AM1jwTJDxVj9CT51ZvYtD5/ZMUGXx6wZc0QubWHpC0T19OwiYdzQsYk39XfSmGjy9oScut7sFkc2s7ok1uRlgsf/EACcQAAEDAgYCAQUAAAAAAAAAAAABAhMUFQMEBSFhYhBSEhEiMEFR/9oACAEBAAE/APDSz8Fn4G6PwWfqWbqJo/Us3BZ+omj9StK0rSZxO4nd+KMjIyIiIiIiIibA90JsH3QmwfdC+di+9hNd7l93X7y+9xmtq5NnFdmPqu/7K7Mf0wdSzLEXlT47qfEY3ZSm3UphmW2UoyjG5PgouCh4G5LjxsIVJUjcyTk43HJicbjeWn//xAAfEQEBAAEFAAMBAAAAAAAAAAAAFBMBAhESYQMQIDD/2gAIAQIBAT8A+6VKlSpUqVKlw4cOmjpo6afykSJEfiPxH4kSJGDROn8SJEiRIkYdjFtbvh2ffLu7u7IyMjKysv4qVKlSpUrWeq/x/8QAHhEBAAICAwEBAQAAAAAAAAAAABIUAhMRIGEBEDD/2gAIAQMBAT8A/bCwst7e3tra2rS0tN+Tfk35fykkkkkkkkl04cOOnOTnJ8+5IooqysrKvir4q+Kvir4q9NbW1NbWgggh0//Z",
  gradient: "data:image/png;base64,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",
  opacity: "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAACACAYAAAAClekiAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAA1ZJREFUeNrcWVuO3EAIBNz5zxXmP/c/Qc4x85VbRCKezXrUxlSBxytFir+86x6a5lEFtN7v928i4vL30fAut9vNt/fp2+sZ0+LtxxYWW3g/CEALNoE6aSBRkwEWzD9m/9cR1J/PauDcFjWw2Wjg3dH3EXbKrK3sW/SCJO6UsInNAtXdv4MdP94fj4dn8bEJGcC/2Xnno7yM/BSwhLNp8jf00Ag7VFoc3kfyQ2Fnjv/fjoCSif0NQ1kTg6GjCQplSeIj+y5j9fMi+PEVD2IOzEJ8oLMRO+wMu+WCsmgk9jCWjQ6icbdmZDAFQjhdwwQIc1+GB9WTuxEIOLgLbfTEgx9s2zVOqDZnjiBdGzCrlwIQhUGhg7BRJ6w9wwMBoasJtekADGTMdfP6rhccEKw+8YB6YcUDlqmSpXNmB8SVjnjBEztkG9gACy3Rwq5mI4zEpYg+ZbRXpTMsrpgXKlTaM9Pq54UhzlQfZMCyY2cjiQQjdHwew5vsfPg+ws6l36OBvzQOBGjCYkPHm8Y7aFAZTFAVs+EBSt25X3CUzpdhfUncZB04e8eNmjUcS8NwkOKrAqPCA9hweNEn2BxISxZhXU9seJAlj0/9Aiy8uuwsjFgW4gGtkiwT0Nl5hwf6JibsvCCNztVRv7AQPKB5UDFTKzojHkiCB1JpYCdKfJqN8g42omzULkLP5MrO6oiAUBx00aktAKJ2FkjeRKcXHiib1Kxxwqo2vWKDEpUZRpziBRpcUQM9Ua0oqpEMUF0GcYdc0GKmlNZICyi0EdHuYT3pF3YaJHhwqtguxwLMC8qQKhZZXd+nyWSktCmpLh7BCKCk2cnGQF7EhV1FpA9hz/nBTwYgU31wuv3XznSnU+qyIQwdA3U6eMumeR12gul8KRK/bAhzTkDAg0M+BDxISxzrzMzYSPQf2wDwYoetD6GsZKEwetds2Er6BNgzoYsYk/ya5IUHv4DKbJ646xf0RAy03OiNnkEydo4XUw4AV9lcmV1KpLxRRSIbwEhmRJY4yhrPynBQ8PisAxVVYqA+OFBb5gUlJe7unslIIJVXSOyeqWq6WuzMRgNlNmpRbAoahSGiVVQrdwbRmuCBb/cLv9mshODBKVCFhDuaIKKVBm8/l0jlPxHwR4ABAF3bekgydK22AAAAAElFTkSuQmCC"
};
html = "<div class='ldcp-panel'><div class='ldcp-v ldcp-g1'><div class='ldcp-h ldcp-g11 ldcp-2d'><div style='top:20px;left:20px' class='ldcp-ptr-circle'></div><img src='" + images.gradient + "'><div class='ldcp-mask'></div></div><div class='ldcp-h ldcp-g12 ldcp-1d ldcp-hue'><div class='ldcp-ptr-bar'></div><img src='" + images.hue + "'><div class='ldcp-mask'></div></div><div class='ldcp-h ldcp-g13 ldcp-1d ldcp-alpha'><div class='ldcp-ptr-bar'></div><div class='ldcp-alpha-img' style='background-image:url(" + images.opacity + ")'></div><div class='ldcp-mask'></div></div></div><div class='ldcp-v ldcp-g2'><div class='ldcp-colors ldcp-h ldcp-g21'><div class='ldcp-palette'><small class='ldcp-idx'></small></div><small class='ldcp-sep'></small><div class='ldcp-color-none'></div><span class='ldcp-cbtn ldcp-btn-add'>+</span><span class='ldcp-cbtn ldcp-btn-remove'>-</span></div></div>\n<div class='ldcp-v ldcp-g3'><div class='ldcp-h ldcp-g31'>\n<div class='ldcp-edit-group'><span>R</span><input class='ldcp-in-r' value='255'><span>G</span><input class='ldcp-in-g' value='255'><span>B</span><input class='ldcp-in-b' value='255'></div>\n<div class='ldcp-edit-group' style='display:none'><span>H</span><input class='ldcp-in-h' value='255'><span>S</span><input class='ldcp-in-s' value='255'><span>L</span><input class='ldcp-in-l' value='255'></div>\n<div class='ldcp-edit-group ldcp-edit-hex' style='display:none'><span>HEX</span><input class='ldcp-in-hex' value='#000000'></div>\n<span>A</span><input value='255' class='ldcp-in-a'>\n<span class='ldcp-caret'>RGBA &#x25be;</span></div></div></div><div class='ldcp-chooser'><button/><button/><button/></div>";
function import$(obj, src){
  var own = {}.hasOwnProperty;
  for (var key in src) if (own.call(src, key)) obj[key] = src[key];
  return obj;
}
