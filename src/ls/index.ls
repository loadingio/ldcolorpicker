angular.module \main, <[ldColorPicker]>
  ..controller \main, <[$scope $timeout]> ++ ($scope, $timeout) ->
    $scope.option = pinned: true
    $scope.$watch 'ldcp', (->)
    $scope.$watch 'color', (->)
    $scope.$watch 'idx', (->)
    $scope.$watch 'pin', (->)
    $scope.$watch 'palette', (->console.log it)

setpalette = (context) ->
  pal = ldColorPicker.palette.get context
  console.log pal
  ldColorPicker.palette.set \landing, pal

<- $(document).ready

ldColorPicker.init!
ldColorPicker.set-palette <[#ac5d53 #e2b955 #f6fcc5 #32b343 #376aa9 #170326]>
ldColorPicker.set-palette \http://localhost/palette/ldwrnh

btn-color = document.getElementById("btn-color")
ldcp = new ldColorPicker(btn-color,{})
ldcp.on \change, (color)-> btn-color.style.color = color

$(\#input).ldColorPicker()

$('#landing .subtitle span[data-toggle=tooltip]').tooltip!
$(\#affix).affix do
  offset: do
    top: $(\#affix).offset!.top

