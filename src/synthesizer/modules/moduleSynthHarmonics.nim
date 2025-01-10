import ../../globals
import ../../utils
import ../../synthesizer/synthInfos
import ../../events
import ../../gui/widgets
import ../../maths
import ../../systemFonts
import moduleSynthGeneric
import modulesEnum
import math
import random

import imguin/[glfw_opengl,cimgui]
import strformat

const MAX_HARMONICS* = 64

type
  HarmonicObject = object
    amp*: float32 = 0
    phase*: float32 = 0
    detune*: int8 = 0

  ModuleSynthHarmonics* = ref object of ModuleSynthGeneric
    harmonics*: array[MAX_HARMONICS, HarmonicObject]
    harmonicsFinal*: array[MAX_HARMONICS, HarmonicObject]
    harmonicsInterpolation*: Adsr
    normalize*: bool = false

    presetNbHarmonics*: uint16 = 8
  ModuleSynthHarmonicsSerialize* = object of ModuleSynthGenericSerialize

proc summon*(_: typedesc[ModuleSynthHarmonics], position: Vec2[float32]): ModuleSynthHarmonics =
  result = ModuleSynthHarmonics(inputs: @[
  PinConnection(moduleIndex: -1, pinIndex: -1), 
  ], outputs: @[PinConnection(moduleIndex: -1, pinIndex: -1)], position: position)
  result.harmonics[0].amp = 1.0
  result.harmonicsFinal[0].amp = 1.0

method getPhase(module: ModuleSynthHarmonics, mac: int32, macLen: int32, detune: int8): float64 {.base.} =
    var mac = mac.float64
    var macLen = macLen.float64

    # Anti-divide by 0
    if(macLen < 1): macLen = 1
    return mac.float64 / (macLen) * detune.float64

method synthesize*(module: ModuleSynthHarmonics, x: float64, pin: int, moduleList: array[MAX_MODULES, ModuleSynthGeneric], synthInfos: SynthInfos, renderWidth: int): float64 =
  let moduleA = if(module.inputs[0].moduleIndex > -1): moduleList[module.inputs[0].moduleIndex] else: return 0
  if(moduleA == nil): return 0

  result = 0.0
  var normalizerPos = 0.0
  var normalizerNeg = 0.0
  let interpPlace = module.harmonicsInterpolation.doAdsr(synthInfos.macroFrame)
  for i in 0..<MAX_HARMONICS:
    if(module.harmonics[i].amp == 0.0 and module.harmonicsFinal[i].amp == 0.0): continue
    let phaseA = module.harmonics[i].phase
    let phaseB = module.harmonicsFinal[i].phase
    let interpolatedPhase = lerp(phaseA, phaseB, interpPlace)

    let ampA = module.harmonics[i].amp
    let ampB = module.harmonicsFinal[i].amp
    let interpolatedAmp = lerp(ampA, ampB, interpPlace)
    result += moduleA.synthesize(moduloFix((x * (i + 1).float64) + interpolatedPhase + module.getPhase(synthInfos.macroFrame, synthInfos.macroLen, module.harmonics[i].detune), 1.0), module.inputs[0].pinIndex, moduleList, synthInfos, renderWidth) * interpolatedAmp
    if(interpolatedAmp > 0.0): normalizerPos += interpolatedAmp.abs()
    else: normalizerNeg += interpolatedAmp.abs()

  let normalizer = max(normalizerPos, normalizerNeg)
  if(module.normalize and normalizer != 0.0):
    result /= normalizer

  result = result.flushToZero()

proc clear*(harmonics: var array[MAX_HARMONICS, HarmonicObject]) =
  for i in 0 ..< MAX_HARMONICS:
    harmonics[i] = HarmonicObject()

proc drawHarmonicsTable(harmonics: var array[MAX_HARMONICS, HarmonicObject], module: ModuleSynthHarmonics, eventList: var EventList) =
  if(igBeginTable("harmonics", 4, ord ImGui_TableFlags_ScrollY, ImVec2(x: 0, y: 216), 320)):
    igTableSetupColumn("index", ImGuiTableColumnFlags_WidthFixed.cint, 0.0, 0)
    igTableSetupColumn("amps", ImGuiTableColumnFlags_WidthFixed.cint, 0.0, 0)
    igTableSetupColumn("phases", ImGuiTableColumnFlags_WidthFixed.cint, 0.0, 0)
    igTableSetupColumn("detunes", ImGuiTableColumnFlags_WidthFixed.cint, 0.0, 0)
    
    for i in 0 ..< MAX_HARMONICS:
      igTableNextRow(0, 0)
      igTableSetColumnIndex(0)
      igText("%d", i + 1)      # First column: display the index
      igTableSetColumnIndex(1)
      igSetNextItemWidth(128)
      sliderFloat32(fmt"##HarmAmp{i}".cstring, harmonics[i].amp.addr, -1.0f, 1.0f, "Amp.: %.4f".cstring, IgSliderFlags.None)
      .treatAction(eventList, fmt"Harmonics: Harm. {i} Amp set to {harmonics[i].amp}")
      igTableSetColumnIndex(2)
      igSetNextItemWidth(128)
      sliderFloat32(fmt"##HarmPhase{i}".cstring, harmonics[i].phase.addr, 0.0f, 1.0f, "Phase: %.4f".cstring, IgSliderFlags.None)
      .treatAction(eventList, fmt"Harmonics: Harm. {i} Phase set to {harmonics[i].phase}")
      igTableSetColumnIndex(3)
      igSetNextItemWidth(64)
      sliderScalar[int8](fmt"##HarmDetune{i}".cstring, IgDataType.S8, addr harmonics[i].detune, -32, 32, "DT: %i", IgSliderFlags.None)
      .treatAction(eventList, fmt"Harmonics: Harm. {i} Detune set to {harmonics[i].detune}")
    igEndTable()
    #checkbox("Normalize", module.normalize.addr)
    toggle("Normalize", module.normalize.addr)
    .treatAction(eventList, fmt"Harmonics: Normalize set to {module.normalize}")
    #igSameLine(0, 2)
    igText("Presets:")
    igSetNextItemWidth(216)
    discard sliderScalar[uint16]("##harmonicCount", IgDataType.U16, module.presetNbHarmonics.addr, 1, MAX_HARMONICS, "Num. harmonics: %d", IgSliderFlags.ClampOnInput)
    igSameLine(0, 2)
    igBeginGroup()
    igPushFont(FONT_AUDIO.getFont())
    if(igButton(fmt"{ICON_FAD_MODSQUARE}", ImVec2(x: 0, y: 0))):
      harmonics.clear()
      # Apply Additive Square
      for i in countup(0, module.presetNbHarmonics.int - 1, 2):
        harmonics[i].amp = 1.0 / (i.float64 + 1.0)
      eventList.push(Event.new(EVENT_NEED_UPDATE, "Harmonics: Applied Additive Square settings"))
    toolTip("Additive Square")
    igSameLine(0, 2)
    if(igButton(fmt"{ICON_FAD_MODSQUARE}##25", ImVec2(x: 0, y: 0))):
      harmonics.clear()
      # Apply Additive 25% Pulse
      for i in 0..<module.presetNbHarmonics.int:
        let harmonicIndex = i + 1
        harmonics[i].amp = (1.0 / (i + 1).float64) * sin((PI / 4) * (i + 1).float64)
        harmonics[i].phase = moduloFix(-0.125 * ((i).float64) + 0.125, 1.0)
      eventList.push(Event.new(EVENT_NEED_UPDATE, "Harmonics: Applied Additive 25% pulse settings"))
    toolTip("Additive 25% Pulse")
    igSameLine(0, 2)
    if igButton(fmt"{ICON_FAD_MODTRI}", ImVec2(x: 0, y: 0)):
      harmonics.clear()
      # Apply Additive Triangle
      for i in countup(0, module.presetNbHarmonics.int - 1, 2):  # Only odd harmonics
        let sign = if (i div 2) mod 2 == 0: 1.0 else: -1.0  # Alternate signs
        harmonics[i].amp = sign * (1.0 / ((i.float64 + 1.0) ^ 2))
        harmonics[i].phase = 0 # Set phase to π/2
      eventList.push(Event.new(EVENT_NEED_UPDATE, "Harmonics: Applied Additive Triangle settings"))
    toolTip("Additive Triangle")
    igSameLine(0, 2)
    if igButton(fmt"{ICON_FAD_MODSAW_DOWN}", ImVec2(x: 0, y: 0)):
      harmonics.clear()
      # Apply Additive Saw
      for i in 0..<module.presetNbHarmonics.int:  # Only odd harmonics
        harmonics[i].amp = 1.0 / (i + 1).float64
        harmonics[i].phase = 0
      eventList.push(Event.new(EVENT_NEED_UPDATE, "Harmonics: Applied Additive Saw settings"))
    toolTip("Additive Saw")
    igSameLine(0, 2)
    if igButton(fmt"{ICON_FAD_RANDOM_1DICE}##1", ImVec2(x: 0, y: 0)):
      harmonics.clear()
      for i in 0..<module.presetNbHarmonics.int:
        if rand(1.0) > 0.5:  # 50% chance to activate a harmonic
          module.harmonics[i].amp = rand(2.0) - 1.0  # Random amplitude
          module.harmonics[i].phase = rand(1.0)  # Random phase
      eventList.push(Event.new(EVENT_NEED_UPDATE, "Harmonics: Applied Additive Noise settings"))
    toolTip("I'm feeling lucky")
    igPopFont()
    igEndGroup()
  
  return

const POPUP_NAME = "Harmonics: Advanced Settings"
import ../../gui/envelopes/guiEnvelopesMain
method `popupTitle`*(module: ModuleSynthHarmonics): string =
  return POPUP_NAME
method drawPopup*(module: ModuleSynthHarmonics, infos: var SynthInfos, eventList: var EventList): void =
  moduleModal(POPUP_NAME, module.popupOpened.addr):
    igBeginTabBar("##TabBar", 0)
    igPushFont(FONT_AUDIO.getFont())
    if(igBeginTabItem(fmt"Second harmonics table", nil, 0)):
      var availlableSpace: ImVec2
      igGetContentRegionAvail(availlableSpace.addr)
      
      igBeginChild_Str("##harmonics", ImVec2(x: availlableSpace.x, y: 0), ord (ImGui_ChildFlags_Borders.int32 or ImGui_ChildFlags_AlwaysAutoResize.int32 or ImGui_ChildFlags_AutoResizeX.int32 or ImGuiChildFlags_AutoResizeY.int32), 0)
      discard miniOsc("ABCD", module.waveDisplay.addr)
      sliderFloat32("##interp", module.harmonicsInterpolation.peak.addr, 0.0f, 1.0f, "Interp: %.4f".cstring, IgSliderFlags.ClampOnInput)
      .treatAction(eventList, fmt"Harmonics: Interpolation set to {module.harmonicsInterpolation.peak}")
      drawHarmonicsTable(module.harmonicsFinal, module, eventList)
      igEndChild()
      igEndTabItem()
    
    if(igBeginTabItem(fmt"{ICON_FAD_ADSR} Interpolation envelope", nil, 0)):
      module.harmonicsInterpolation.draw(module, infos, 0, 1, eventList, moduleTitles[MODULE_OSCILLATOR].data, "Phase", strictClip = true)
      igEndTabItem()
    igPopFont()
    igEndTabBar()

method draw*(module: ModuleSynthHarmonics, infos: var SynthInfos, modifiable: bool, eventList: var EventList): EventModuleGui =
  discard miniOsc("ABCD", module.waveDisplay.addr)
  
  drawHarmonicsTable(module.harmonics, module, eventList)

  if(advancedSettingsButton()):
    module.popupOpened = true
    return GUI_OPEN_POPUP

method `title`*(module: ModuleSynthHarmonics): Text =
  return moduleTitles[MODULE_HARMONICS]

method `contentWidth`*(module: ModuleSynthHarmonics): float32 =
  return 384.0