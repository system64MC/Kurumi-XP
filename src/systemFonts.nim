import std/[strutils, math]
import nimgl/[opengl,glfw]

import imguin/[glfw_opengl,cimgui]
import imguin/lang/imgui_ja_gryph_ranges

import fonts/pc98
import fonts/IconsFontAwesome6 as fa6
import fonts/IconsFontAudio as fad

const fontAwesomeFile = staticRead("fonts/fa6/fa-solid-900.ttf")
let fontAwesomeData = fontAwesomeFile

const fontAudioFile = staticRead("fonts/fontaudio.ttf")
let fontAudioData = fontAudioFile


proc new_ImFontConfig(): ImFontConfig =
  #[Custom constructor with default params taken from imgui.h]#
  result.FontDataOwnedByAtlas = true
  result.FontNo = 0
  result.OversampleH = 3
  result.OversampleV = 1
  result.PixelSnapH = false
  result.GlyphMaxAdvanceX = float.high
  result.RasterizerMultiply = 1.0
  result.RasterizerDensity  = 1.0
  result.MergeMode = false
  result.EllipsisChar = cast[ImWchar](-1)


var fonts: seq[ptr ImFont] = @[nil, nil, nil]

type 
  FontBank* = enum
    FONT_AWESOME
    FONT_AUDIO
    FONT_AWESOME_ALONE

  Text* = object
    bank* : FontBank
    data* : string

proc new*(t: typedesc[Text], bank: FontBank, data: string): Text =
  Text(bank: bank, data: data)

template withFont*(fontBank: FontBank, body: untyped): untyped =
  igPushFont(fonts[ord(fontBank)])
  body
  igPopFont()

proc getFont*(f: FontBank): ptr ImFont = fonts[ord(f)]

proc initFonts*() =
  let io = igGetIO()
  io.Fonts.ImFontAtlas_ClearFonts()

  var config = new_ImFontConfig()
  config.SizePixels = 16
  #io.Fonts.ImFontAtlas_AddFontFromMemoryTTF(pc98Font[0].addr, pc98Font.len, 16, config.addr, cast[ptr ImWchar](addr glyphRangesJapanese))
  io.Fonts.ImFontAtlas_AddFontFromMemoryTTF(pc98Font[0].addr, pc98Font.len, 16, config.addr, nil)
  const ranges_icon_fonts = [ICON_MIN_FA.uint16,  ICON_MAX_FA.uint16, 0]
  const range_audio = [ICON_MIN_FAD.uint16,  ICON_MAX_FAD.uint16, 0]
  const range_audio2 = [0xF800.uint16, 0xF8FF, 0]
  config.MergeMode = true
  var fontAwesome = io.Fonts.ImFontAtlas_AddFontFromMemoryTTF(fontAwesomeData[0].addr, fontAwesomeData.len.int32, 16, config.addr, ranges_icon_fonts[0].addr)

  fonts[0] = fontAwesome

  config.MergeMode = false
  io.Fonts.ImFontAtlas_AddFontFromMemoryTTF(pc98Font[0].addr, pc98Font.len, 16, config.addr, nil)
  config.MergeMode = true
  config.GlyphOffset.y += 5.0
  var fontAudio = io.Fonts.ImFontAtlas_AddFontFromMemoryTTF(fontAudioData[0].addr, fontAudioData.len.int32, 20, config.addr, range_audio[0].addr)
  fonts[1] = fontAudio
  config.MergeMode = false
  config.GlyphOffset.y = 0.0
  var fontAwesomeAlone = io.Fonts.ImFontAtlas_AddFontFromMemoryTTF(fontAwesomeData[0].addr, fontAwesomeData.len.int32, 16, config.addr, ranges_icon_fonts[0].addr)
  fonts[2] = fontAwesomeAlone
  io.Fonts.ImFontAtlas_Build()

export fa6
export fad