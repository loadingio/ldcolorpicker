# 1.0.0 interface

class member
o PalPool
    hash: do
      default: [...]
    add: (ctx, pal) ->
    bind: (ctx, ldcp) ->
    remove: (ctx) ->
    random: ->

object member
  pal

  setPos
  updateDimension

  getIdx
  setIdx
  syncPalette
  bindPalette
  getPalette
  setPalette
  getColor(type)
  setColor
  getAlpha
  setAlpha
  setPin
  isPinned
  addColor
  removeColor
  toggle
  on


# 0.1.4 interface
class member
  set-palette: ->
  palette: 
    members
    set
    get
    get-val
    update
    random
    val
  mouse
    start
  init


object member
    load-palette: ->
  o add-color: ->
  o remove-color: ->
    next-edit-mode: ->
    edit: ->
    update-dimension: ->
    click-toggle: ->
    toggle-config: ->
  i event-handler: {}
  x event-queue: {}

  i handle: ->
  o on: ->

  o toggle: ->

  x random: ->

  o get-palette: ->
  o set-palette: ->

    set-color: ->
    update-palette: -> 用來更新 palette visual, 同時設定 input & idx
    update-color: ->

  x convert: {}

  x toRgba: ->

  x hex: ->

  x getHslaString: ->
  x toHslaString: ->

  x getRgbaString: ->
  x toRgbaString: ->

  x getHexString: ->
  x toHexString: ->

  x get-value: ->
  x to-value: ->

  o is-pinned: ->
  o set-pin: ->

  o get-idx: ->
  o set-idx: ->

  o set-alpha: ->
  o get-alpha: ->

  x toggle-none: ->  # need to consider "none" or "transparent" color

  x set-hsl: ->

  i set-pos: ->
  i move: ->

  i palette: []
