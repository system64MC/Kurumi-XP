import ../../globals
import ../../utils
import ../../synthesizer/synthInfos
import ../../events
import ../../gui/widgets
import ../../maths
import ../../systemFonts
import ../../fonts/IconsFontAwesome6
import ../../fonts/IconsFontAudio
import moduleSynthGeneric
import modulesEnum
import math

import imguin/[glfw_opengl,cimgui]
import strformat

type
  ModuleSynthMorpher* = ref object of ModuleSynthGeneric
    morph: Adsr = Adsr(peak: 0.0)
  ModuleSynthMorpherSerialize* = object of ModuleSynthGenericSerialize

proc summon*(_: typedesc[ModuleSynthMorpher], position: Vec2[float32]): ModuleSynthMorpher =
  return ModuleSynthMorpher(
    inputs: @[
      PinConnection(moduleIndex: -1, pinIndex: -1),
      PinConnection(moduleIndex: -1, pinIndex: -1),
      PinConnection(moduleIndex: -1, pinIndex: -1),
      PinConnection(moduleIndex: -1, pinIndex: -1),
      PinConnection(moduleIndex: -1, pinIndex: -1),
    ], outputs: @[PinConnection(moduleIndex: -1, pinIndex: -1)], position: position)

proc lerp(x, y, a: float64): float64 =
  return x*(1-a) + y*a  

method synthesize*(module: ModuleSynthMorpher, x: float64, pin: int, moduleList: array[MAX_MODULES, ModuleSynthGeneric], synthInfos: SynthInfos): float64 =
  let morphValue = module.morph.doAdsr(synthInfos.macroFrame)
  let morphValueInt = morphValue.int

  let pinA = if(morphValueInt < module.inputs.len): module.inputs[morphValueInt] else: PinConnection(moduleIndex: -1, pinIndex: -1)
  let pinB = if(morphValueInt + 1 < module.inputs.len): module.inputs[morphValueInt + 1] else: PinConnection(moduleIndex: -1, pinIndex: -1)

  let moduleA = if(pinA.moduleIndex > -1 and pinA.pinIndex > -1): moduleList[pinA.moduleIndex] else: nil
  let moduleB = if(pinB.moduleIndex > -1 and pinB.pinIndex > -1): moduleList[pinB.moduleIndex] else: nil
  let valA = if(moduleA != nil): moduleA.synthesize(x, module.inputs[morphValueInt].pinIndex, moduleList, synthInfos) else: 0.0
  let valB = if(moduleB != nil): moduleB.synthesize(x, module.inputs[morphValueInt + 1].pinIndex, moduleList, synthInfos) else: 0.0

  return lerp(valA, valB, morphValue - morphValueInt.float)

const POPUP_NAME = "Morpher: Advanced Settings"
import ../../gui/envelopes/guiEnvelopesMain
method drawPopup*(module: ModuleSynthMorpher, infos: var SynthInfos, eventList: var EventList): void =
  moduleModal(POPUP_NAME, module.popupOpened.addr):
    igBeginTabBar("##TabBar", 0)
    igPushFont(FONT_AUDIO.getFont())
    if(igBeginTabItem(fmt"{ICON_FAD_ADSR} Morph envelope", nil, 0)):
      module.morph.draw(module, infos, 0, (module.inputs.len - 1).float, eventList, moduleTitles[MODULE_OSCILLATOR].data, "Phase")
      igEndTabItem()
    igPopFont()
    igEndTabBar()

method `contentWidth`*(module: ModuleSynthMorpher): float32 =
  return 128.0
method draw*(module: ModuleSynthMorpher, infos: var SynthInfos, modifiable: bool, eventList: var EventList): EventModuleGui =
  discard miniOsc("ABCD", module.waveDisplay.addr)
  const KNOB_SIZE = 64
  centerElementX(KNOB_SIZE)
  knobFloat[float32]("Morph", module.morph.peak.addr, 0.0f, 4.0f, 10, size = KNOB_SIZE, clip_min = 0, clip_max = (module.inputs.len - 1).float, clip = true)
  .treatAction(eventList, fmt"Morpher: Morph set to {module.morph.peak}")
  if(advancedSettingsButton()):
    module.popupOpened = true
    return GUI_OPEN_POPUP
  # igText(fmt"inputs: {module.inputs}")
  # igEndChild()

method `popupTitle`*(module: ModuleSynthMorpher): string =
  return POPUP_NAME

method `title`*(module: ModuleSynthMorpher): Text =
  return moduleTitles[MODULE_MORPHER]
