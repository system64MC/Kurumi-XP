import unicode
import strutils

import ../fonts/IconsFontAwesome6
import ../fonts/IconsFontAudio

const offsetSubtract = ICON_MIN_FAD - ICON_MAX_FA

proc toUnicode*(s: string): uint16 =
  return s.runeAt(0).uint16

proc toRuneStr*(c: uint16): string =
  return c.Rune.toUTF8()

proc getFontAudioChar*(c: string): string =
  let u = c.toUnicode().int + offsetSubtract
  return u.uint16.toRuneStr()