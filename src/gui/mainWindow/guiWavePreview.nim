import std/[strutils, math]
import nimgl/[opengl,glfw]

import imguin/[glfw_opengl,cimgui]

import ../../globals
import ../../synthesizer/synth
import ../../app
import ../../maths
import ../../systemFonts
import ../../events

import ../widgets

import strformat

proc generateWaveStr*(synth: Synth): string =
  var str = ""
  for i in 0..<synth.synthInfos.waveDims.x:
    if(synth.textAsHex and not synth.textAsSigned):
      var num = $(synth.waveOutputInt[i]).toHex().strip(true, chars = {'0'})
      if(num == ""): num = "0"
      str &= num & " "
    else:
      str &= $synth.waveOutputInt[i] & " "

  return str & ";"

proc generateSeqStr*(synth: Synth): string =
  let macroBackup = synth.synthInfos.macroFrame
  var outStr = ""
  for mac in 0..<synth.synthInfos.macroLen:
    synth.synthInfos.macroFrame = mac
    synth.synthesize()
    outStr &= synth.generateWaveStr() & "\n"
  synth.synthInfos.macroFrame = macroBackup
  synth.synthesize()
  return outStr

proc drawWavePreview*(app: KuruApp) =
  var availlableSpace: ImVec2
  igGetContentRegionAvail(availlableSpace.addr)
  
  if(igBeginChild_Str("wavePreview", ImVec2(x: availlableSpace.x - igGetStyle().ItemSpacing.x, y: 512), ImGui_ChildFlags_Borders.cint, 0)):
    let previewSizeX = 256 + igGetStyle().ItemSpacing.x * 2
    let previewSizeY = 256 + igGetStyle().ItemSpacing.y * 2
    igGetContentRegionAvail(availlableSpace.addr)
    igSetCursorPosX((availlableSpace.x - 256) * 0.5)
    igBeginChild_Str("waveformPreview", ImVec2(x: 260, y: 260), ImGui_ChildFlags_Borders.cint, 0)
    let dl = igGetWindowDrawList()
    var pos: ImVec2
    igGetWindowPos(pos.addr)
    # igGetCursorScreenPos(pos.addr)

    let col1 = globalColorsScheme[GlobalCol_WavePrev1].igColorConvertFloat4ToU32()
    let col2 = globalColorsScheme[GlobalCol_WavePrev2].igColorConvertFloat4ToU32()
    let colLine = globalColorsScheme[GlobalCol_WavePrevLine].igColorConvertFloat4ToU32()


    for i in 0..<app.synth.synthInfos.waveDims.x:
      let x1 = (i.float64 * 256.0 / app.synth.synthInfos.waveDims.x.float64).float32
      let x2 = ((i.float64 * 256.0 / app.synth.synthInfos.waveDims.x.float64) + (256.0 / app.synth.synthInfos.waveDims.x.float64)).float32
      let sample = (app.synth.waveOutputInt[i].float64 * (255.0/app.synth.synthInfos.waveDims.y.float64) + (app.synth.synthInfos.waveDims.y.float64/2)*(255.0/app.synth.synthInfos.waveDims.y.float64)).float32 
      let sample1 = (app.synth.waveOutputInt[(i + 1) mod app.synth.synthInfos.waveDims.x].float64 * (255.0/app.synth.synthInfos.waveDims.y.float64) + (app.synth.synthInfos.waveDims.y.float64/2)*(255.0/app.synth.synthInfos.waveDims.y.float64)).float32 
      let s = ((-sample + 384).float / 128) - 1
      let col = colorLerp(col2, col1, s.abs())
      dl.ImDrawList_AddRectFilledMultiColor(
        pos + ImVec2(x: x1 + 2, y: 128 + 2),    
        pos + ImVec2(x: x2 + 2, y: -sample + 384 + 2),
        col2, 
        col2, 
        col,
        col,
      )
      
      dl.ImDrawList_AddLine(
        pos + ImVec2(x: x2 + 2, y: -sample + 384 + 2),
        pos + ImVec2(x: x2 + 2, y: -sample1 + 384 + 2),
        colLine, 2.0
      )

      dl.ImDrawList_AddLine(
        pos + ImVec2(x: x1 + 2, y: -sample + 384 + 2),
        pos + ImVec2(x: x2 + 2, y: -sample + 384 + 2),
        colLine, 2.0
      )

    igEndChild()
        
    let tmpWaveWidth: int32 = 0
    let tmpWaveHeight: int32 = 0

    sliderScalar[int32]("##waveformWidth", IgDataType.S32, 
      app.synth.synthInfos.waveDims.x.addr, 1, 256, 
      "Width: %d", IgSliderFlags.None,
      clip_min = 0,
      clip_max = 4096,
      clip = true
    )
    .treatAction(app.events, fmt"Wave length set to {app.synth.synthInfos.waveDims.x}")

    sliderScalar[int32]("##waveformHeight", IgDataType.S32, 
      app.synth.synthInfos.waveDims.y.addr, 1, 255, 
      "Height: %d", IgSliderFlags.None,
      clip_min = 1,
      clip_max = int32.high,
      clip = true
    )
    .treatAction(app.events, fmt"Wave height set to {app.synth.synthInfos.waveDims.y}")
    
    let action = sliderScalar[int32]("##MacroLen", IgDataType.S32, 
      app.synth.synthInfos.macroLen.addr, 1, 256, 
      "Seq. Len.: %d", IgSliderFlags.None,
      clip_min = 1,
      clip_max = int16.high,
      clip = true
    )
    if(action != WIDGET_NONE):
      app.synth.synthInfos.macroFrame = clamp(app.synth.synthInfos.macroFrame, 0, app.synth.synthInfos.macroLen - 1)
    action.treatAction(app.events, fmt"Sequence length set to {app.synth.synthInfos.macroLen}")
    
    knobInteger[int32]("Seq.\nFrame", app.synth.synthInfos.macroFrame.addr, 0, app.synth.synthInfos.macroLen - 1, 0, size = 64, clip_min = 0, clip_max = app.synth.synthInfos.macroLen - 1, clip = true).treatAction(app.events, fmt"Sequence frame set to {app.synth.synthInfos.macroFrame}")
    igSameLine(0, 2)
    knobInteger[int32]("\nOversample", app.synth.synthInfos.oversample.addr, 1, 8, 0, size = 64, clip_min = 1, clip_max = 8, clip = true).treatAction(app.events, fmt"Oversample set to {app.synth.synthInfos.oversample}")
    igSameLine(0, 4)
    igBeginChild_Str("Copy waveform", ImVec2(x: 0, y: 0), ImGui_ChildFlags_Borders.cint, 0)
    if(igRadioButton_Bool("Dec", not app.synth.textAsHex)):
      app.synth.textAsHex = false
    igSameLine(0, 4)
    if(igRadioButton_Bool("Hex", app.synth.textAsHex)):
      app.synth.textAsHex = true
    if(not app.synth.textAsHex):
      igSameLine(0, 4)
      if(igButton(if(app.synth.textAsSigned): fmt"{ICON_FA_PLUS_MINUS}" else: fmt"{ICON_FA_PLUS}", ImVec2(x: 24, y: 24))):
        app.synth.textAsSigned = not app.synth.textAsSigned
      if(igIsItemHovered(0)):
        igSetTooltip(if(app.synth.textAsSigned): "Signed" else: "Unsigned")
    #igCheckbox("Sequence", app.synth.textSequence.addr)
    discard toggle("Sequence", app.synth.textSequence.addr)
    if(igButton(fmt"{ICON_FA_CLIPBOARD} Copy to clipboard", ImVec2(x: 0, y: 0))):
      igSetClipboardText(if(app.synth.textSequence): app.synth.generateSeqStr() else: app.synth.generateWaveStr())
    igEndChild()

    #sliderScalar[int32]("##MacroFrame", IgDataType.S32, 
    #  app.synth.synthInfos.macroFrame.addr, 0, app.synth.synthInfos.macroLen - 1, 
    #  "Seq. Index: %d",
    #  flags = IgSliderFlags.ClampOnInput
    #).treatAction(app.events, fmt"Sequence frame set to {app.synth.synthInfos.macroFrame}")

    igEndChild()