setpalette = (context) ->
  pal = ldcolorpicker.PalPool.get context
  ldcolorpicker.PalPool.set \landing, pal

#ldcolorpicker.set-palette <[#ac5d53 #e2b955 #f6fcc5 #32b343 #376aa9 #170326]>

ld$.find '.ldcolorpicker' .map (n) ->
  new ldcolorpicker n, {inline: true}
ld$.find '[data-toggle=ldcolorpicker]' .map (n) ->
  new ldcolorpicker n, {}

btn-color = document.getElementById("btn-color")
ldcp = new ldcolorpicker(btn-color,{})
ldcp.on \change, (color) -> btn-color.style.color = ldcolor.web(color)

#$(\#input).ldColorPicker()
#
#$('#landing .subtitle span[data-toggle=tooltip]').tooltip!
#$(\#affix).affix do
#  offset: do
#    top: $(\#affix).offset!.top

