var x$,setpalette;x$=angular.module("main",["ldColorPicker"]),x$.controller("main",["$scope","$timeout"].concat(function(t){return t.option={pinned:!0},t.$watch("ldcp",function(){}),t.$watch("color",function(){}),t.$watch("idx",function(){}),t.$watch("pin",function(){}),t.$watch("palette",function(){})})),setpalette=function(t){var e;return e=ldColorPicker.palette.get(t),ldColorPicker.palette.set("landing",e)},$(document).ready(function(){var t,e;return ldColorPicker.init(),ldColorPicker.setPalette(["#ac5d53","#e2b955","#f6fcc5","#32b343","#376aa9","#170326"]),ldColorPicker.setPalette("http://localhost/palette/ldwrnh"),t=document.getElementById("btn-color"),e=new ldColorPicker(t,{}),e.on("change",function(e){return t.style.color=e}),$("#input").ldColorPicker(),$("#landing .subtitle span[data-toggle=tooltip]").tooltip(),$("#affix").affix({offset:{top:$("#affix").offset().top}})});