<- $(document).ready
ldColorPicker.init!
ldColorPicker.set-palette <[#ac5d53 #e2b955 #f6fcc5 #32b343 #376aa9 #170326]>
ldColorPicker.set-palette \http://localhost/palette/ldwrnh

blah = document.getElementById("blah")
for i from 0 til 360
  hex = ldColorPicker.prototype.toHexString {hue: i, sat: 1, lit: 0.5}
  div = document.createElement("div")
  div.style.background = hex
  blah.appendChild(div)
