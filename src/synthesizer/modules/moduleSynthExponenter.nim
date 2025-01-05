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

import imguin/[glfw_opengl,cimgui]
import strformat

type
  ModuleSynthExponenter* = ref object of ModuleSynthGeneric
    exp: Adsr = Adsr(peak: 1.0)
  ModuleSynthExponenterSerialize* = object of ModuleSynthGenericSerialize

proc summon*(_: typedesc[ModuleSynthExponenter], position: Vec2[float32]): ModuleSynthExponenter =
  return ModuleSynthExponenter(inputs: @[PinConnection(moduleIndex: -1, pinIndex: -1)], outputs: @[PinConnection(moduleIndex: -1, pinIndex: -1)], position: position)

method synthesize*(module: ModuleSynthExponenter, x: float64, pin: int, moduleList: array[MAX_MODULES, ModuleSynthGeneric], synthInfos: SynthInfos): float64 =
  if(module.inputs[0].moduleIndex < 0): return 0
  let moduleA = moduleList[module.inputs[0].moduleIndex]
  if(moduleA == nil): return 0 
  let exp = module.exp.doAdsr(synthInfos.macroFrame)
  let val = moduleA.synthesize(moduloFix(x, 1.0), module.inputs[0].pinIndex, moduleList, synthInfos)
  let output = pow(abs(val), exp).copySign(val)
  if(isNaN(output)): return 0 else: return output.flushToZero()


const POPUP_NAME = "Exponenter: Advanced Settings"
import ../../gui/envelopes/guiEnvelopesMain
method `popupTitle`*(module: ModuleSynthExponenter): string =
  return POPUP_NAME
method drawPopup*(module: ModuleSynthExponenter, infos: var SynthInfos, eventList: var EventList): void =
  moduleModal(POPUP_NAME, module.popupOpened.addr):
    igBeginTabBar("##TabBar", 0)
    igPushFont(FONT_AUDIO.getFont())
    if(igBeginTabItem(fmt"{ICON_FAD_ADSR} Exponent envelope", nil, 0)):
      module.exp.draw(module, infos, 0, 1, eventList, moduleTitles[MODULE_OSCILLATOR].data, "Phase")
      igEndTabItem()
    igPopFont()
    igEndTabBar()

method draw*(module: ModuleSynthExponenter, infos: var SynthInfos, modifiable: bool, eventList: var EventList): EventModuleGui =
  discard miniOsc("ABCD", module.waveDisplay.addr)
  const MAX_EXP = 16
  const KNOB_SIZE = 64
  centerElementX(KNOB_SIZE)
  knobFloat[float32]("Exp", module.exp.peak.addr, 0.0f, MAX_EXP, MAX_EXP, size = KNOB_SIZE)
  .treatAction(eventList, fmt"Exponenter: Exp set to {module.exp.peak}")
  if(advancedSettingsButton()):
    module.popupOpened = true
    return GUI_OPEN_POPUP
  # igText(fmt"inputs: {module.inputs}")
  # igEndChild()

method `title`*(module: ModuleSynthExponenter): Text =
  return moduleTitles[MODULE_EXPONENTER]

method `contentWidth`*(module: ModuleSynthExponenter): float32 =
  return 128.0