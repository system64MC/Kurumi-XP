import ../../globals
import ../../utils
import ../../events
import ../../maths
import ../synthInfos
import ../../gui/widgets
import ../../systemFonts
import ../../fonts/IconsFontAwesome6
import ../../fonts/IconsFontAudio
import moduleSynthGeneric
import modulesEnum
import math

import imguin/[glfw_opengl,cimgui]

type
  OscType* {.size:1.} = enum
    OSC_SINE
    OSC_SQUARE
    OSC_TRIANGLE
    OSC_SAW
    OSC_MAX

  ModuleSynthOscillator* = ref object of ModuleSynthGeneric
    phase: Adsr
    duty: Adsr = Adsr(peak: 0.5)
    distortionPlace: Adsr = Adsr(peak: 0.5)
    oscType: OscType = OSC_SINE
    mult: uint8 = 1
    detune: int8 = 0
    perfectShape: bool = false
    
  ModuleSynthOscillatorSerialize* = object of ModuleSynthGenericSerialize

var oscStrings: array[OSC_MAX, cstring]
oscStrings[OSC_SINE] = "Sine"
oscStrings[OSC_SQUARE] = "Square"
oscStrings[OSC_TRIANGLE] = "Triangle"
oscStrings[OSC_SAW] = "Saw"

proc summon*(_: typedesc[ModuleSynthOscillator], position: Vec2[float32]): ModuleSynthOscillator =
  return ModuleSynthOscillator(inputs: @[], outputs: @[PinConnection(moduleIndex: -1, pinIndex: -1)], position: position)

method getMult(module: ModuleSynthOscillator): float64 {.base.} =
  if(module.mult == 0): return 0.5 else: return module.mult.float64

method getPhase(module: ModuleSynthOscillator, mac: int32, macLen: int32): float64 {.base.} =
  var mac = mac.float64
  var macLen = macLen.float64

    # Anti-divide by 0
  if(macLen < 1): macLen = 1
  return mac.float64 / (macLen) * module.detune.float64

proc getFinalPhase(module: ModuleSynthOscillator, x: float64, synthInfos: SynthInfos): float64 =
  let distortX = module.duty.doAdsr(synthInfos.macroFrame)
  let dPlace = module.distortionPlace.doAdsr(synthInfos.macroFrame)
  var x = x
  let phaseOff = moduloFix(((dPlace - 0.5) * (distortX - 0.5) * 2) * (if(dPlace >= 0.5): 1.0 else: -1.0), 1)
  let myMult = module.getMult()
  x = (x * myMult) + (module.phase.doAdsr(synthInfos.macroFrame) + module.getPhase(synthInfos.macroFrame, synthInfos.macroLen) + phaseOff )
  x = moduloFix(x + (dPlace - 0.5), 1)
  #x = (x + (dPlace - 0.5))
  if(x < distortX):
    x = linearInterpolation(0, 0, distortX, 0.5, x)
  else:
    x = linearInterpolation(distortX, 0.5, 1, 1, x)
  return moduloFix(x - (dPlace - 0.5), 1)
  #return (x - (dPlace - 0.5))
  

proc sine(module: ModuleSynthOscillator, x: float64, synthInfos: SynthInfos): float64 =
  var x = module.getFinalPhase(x, synthInfos)
  return sin(x * PI * 2)

proc square(module: ModuleSynthOscillator, x: float64, synthInfos: SynthInfos): float64 =
  var x = module.getFinalPhase(x, synthInfos)
  if(x < 0.5): return 1 else: return -1

proc triangle(module: ModuleSynthOscillator, x: float64, synthInfos: SynthInfos): float64 =
  #var x = (moduloFix(x, 1) * synthInfos.waveDims.x.float * synthInfos.oversample.float) / ((synthInfos.waveDims.x.float * synthInfos.oversample.float) - 1)
  var x = module.getFinalPhase(x, synthInfos)
  #return arcsin(sin(x * PI * 2)) / (PI * 0.5)
  return 4.0 * (0.5 - abs(0.5 - moduloFix(x + 0.25, 1))) - 1.0
  #return 4.0 * (0.5 - abs(0.5 - myX)) - 1.0

proc saw(module: ModuleSynthOscillator, x: float64, synthInfos: SynthInfos): float64 =
  var x = module.getFinalPhase(x, synthInfos)
  #x = (moduloFix(x, 1) * synthInfos.waveDims.x.float * synthInfos.oversample.float) / ((synthInfos.waveDims.x.float * synthInfos.oversample.float) - 1)
  return (moduloFix(x + 0.5, 1) * 2) - 1
  #return (myX * 2) - 1

method synthesize*(module: ModuleSynthOscillator, x: float64, pin: int, moduleList: array[MAX_MODULES, ModuleSynthGeneric], synthInfos: SynthInfos, renderWidth: int): float64 =
  #let x = x + (0.5 / (synthInfos.waveDims.x.float64 * synthInfos.oversample.float64))
  case module.oscType
  of OSC_SINE: result = module.sine(x, synthInfos)
  of OSC_SQUARE: result = module.square(x, synthInfos)
  of OSC_TRIANGLE: result = module.triangle(x, synthInfos)
  of OSC_SAW: result = module.saw(x, synthInfos)
  else: result = 0
  result = result.flushToZero()
  # return module.sine(x, synthInfos)

import strformat


const POPUP_NAME = "Oscillator: Advanced Settings"
import ../../gui/envelopes/guiEnvelopesMain
method `popupTitle`*(module: ModuleSynthOscillator): string =
  return POPUP_NAME
method drawPopup*(module: ModuleSynthOscillator, infos: var SynthInfos, eventList: var EventList): void =
  moduleModal(POPUP_NAME, module.popupOpened.addr):
    igBeginTabBar("##TabBar", 0)
    igPushFont(FONT_AUDIO.getFont())
    if(igBeginTabItem(fmt"{ICON_FAD_ADSR} Phase envelope", nil, 0)):
      module.phase.draw(module, infos, 0, 1, eventList, moduleTitles[MODULE_OSCILLATOR].data, "Phase")
      igEndTabItem()
    
    if(igBeginTabItem(fmt"{ICON_FAD_ADSR} Duty envelope", nil, 0)):
      module.duty.draw(module, infos, 0, 1, eventList, moduleTitles[MODULE_OSCILLATOR].data, "Duty")
      igEndTabItem()

    if(igBeginTabItem(fmt"{ICON_FAD_ADSR} Duty place envelope", nil, 0)):
      module.distortionPlace.draw(module, infos, 0, 1, eventList, moduleTitles[MODULE_OSCILLATOR].data, "Duty Place")
      igEndTabItem()
    igPopFont()
    igEndTabBar()

import flatty
method `contentWidth`*(module: ModuleSynthOscillator): float32 =
  return 200.0
method draw*(module: ModuleSynthOscillator, infos: var SynthInfos, modifiable: bool, eventList: var EventList): EventModuleGui =
  igSetCursorPos(ImVec2(x: igGetCursorPosX() + (module.contentWidth - 128) / 2, y: igGetCursorPosY()))
  igBeginGroup()
  discard miniOsc("ABCD", module.waveDisplay.addr)
  igSetNextItemWidth(128)
  sliderFloat32("##Phase".cstring, module.phase.peak.addr, 0.0f, 1.0f, "Phase: %.4f".cstring, IgSliderFlags.None)
  .treatAction(eventList, fmt"Oscillator: Phase set to {module.phase.peak}")
  igSetNextItemWidth(128)
  sliderFloat32("##Duty".cstring, module.duty.peak.addr, 0.0f, 1.0f, "Duty: %.4f".cstring, IgSliderFlags.None)
  .treatAction(eventList, fmt"Oscillator: Duty set to {module.duty.peak}")
  sliderFloat32("##Dist".cstring, module.distortionPlace.peak.addr, 0.0f, 1.0f, "D. Place: %.4f".cstring, IgSliderFlags.None)
  .treatAction(eventList, fmt"Oscillator: Distortion place set to {module.distortionPlace.peak}")
  igEndGroup()

  # 3 x 64 because we have 3 knobs of size 64.
  const KNOB_SIZE = 64.0
  const KNOB_OFFSET = 3.0
  centerElementX(3 * KNOB_SIZE + (2 * KNOB_OFFSET))
  igBeginGroup()
  knobInteger[uint8]("Osc.", cast[ptr uint8](addr module.oscType), OSC_SINE.uint8, OSC_MAX.uint8 - 1, OSC_MAX.cint, format = oscStrings[module.oscType], size = KNOB_SIZE)
  .treatAction(eventList, fmt"Oscillator: Type set to {oscStrings[module.oscType]}")
  igSameLine(0, KNOB_OFFSET)
  knobInteger[uint8]("Mult.", addr module.mult, 0.uint8, 32, 0.cint, size = KNOB_SIZE)
  .treatAction(eventList, fmt"Oscillator: Mult set to {module.mult}")
  igSameLine(0, KNOB_OFFSET)
  knobInteger[int8]("DT.", addr module.detune, -32, 32, 0.cint, size = KNOB_SIZE)
  .treatAction(eventList, fmt"Oscillator: Detune set to {module.detune}")
  igEndGroup()
  if(advancedSettingsButton()):
    module.popupOpened = true
    return GUI_OPEN_POPUP

method `title`*(module: ModuleSynthOscillator): Text =
  return moduleTitles[MODULE_OSCILLATOR]

