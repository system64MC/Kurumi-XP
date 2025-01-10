# Package

version       = "0.1.0"
author        = "system64MC"
description   = "New version of the Kurumi wavetable workstation"
license       = "MIT"
srcDir        = "src"
bin           = @["kurumiXP"]


# Dependencies

requires "nim >= 2.2.0"
requires "https://github.com/dinau/imguin#head"
requires "https://github.com/DavideGalilei/nimpresence"
requires "https://github.com/beef331/miniaudio"
requires "flatty"
requires "zigcc"
requires "malebolgia"
#requires "miniaudio"