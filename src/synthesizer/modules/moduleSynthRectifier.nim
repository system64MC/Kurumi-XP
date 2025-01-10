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
  ModuleSynthRectifier* = ref object of ModuleSynthGeneric
    rectLevel: Adsr = Adsr(peak: 0.0)
    posOrNeg: uint8 = 0
  ModuleSynthRectifierSerialize* = object of ModuleSynthGenericSerialize

proc summon*(_: typedesc[ModuleSynthRectifier], position: Vec2[float32]): ModuleSynthRectifier =
  return ModuleSynthRectifier(inputs: @[PinConnection(moduleIndex: -1, pinIndex: -1)], outputs: @[PinConnection(moduleIndex: -1, pinIndex: -1)], position: position)

method synthesize*(module: ModuleSynthRectifier, x: float64, pin: int, moduleList: array[MAX_MODULES, ModuleSynthGeneric], synthInfos: SynthInfos, renderWidth: int): float64 =
  if(module.inputs[0].moduleIndex < 0): return 0
  let moduleA = moduleList[module.inputs[0].moduleIndex]
  if(moduleA == nil): return 0
  result = moduleA.synthesize(moduloFix(x, 1.0), module.inputs[0].pinIndex, moduleList, synthInfos, renderWidth)

  if(module.posOrNeg == 0): # if negative
    if(result < 0.0): result = module.rectLevel.doAdsr(synthInfos.macroFrame)
  else:
    if(result >= 0.0): result = module.rectLevel.doAdsr(synthInfos.macroFrame)
  result = result.flushToZero()


const POPUP_NAME = "Rectifier: Advanced Settings"
import ../../gui/envelopes/guiEnvelopesMain
method drawPopup*(module: ModuleSynthRectifier, infos: var SynthInfos, eventList: var EventList): void =
  moduleModal(POPUP_NAME, module.popupOpened.addr):
    igBeginTabBar("##TabBar", 0)
    igPushFont(FONT_AUDIO.getFont())
    if(igBeginTabItem(fmt"{ICON_FAD_ADSR} Rectifier envelope", nil, 0)):
      module.rectLevel.draw(module, infos, -1, 1, eventList, moduleTitles[MODULE_OSCILLATOR].data, "Rectifier")
      igEndTabItem()
    igPopFont()
    igEndTabBar()


const modes = ["Negative".cstring, "Positive"]
method `contentWidth`*(module: ModuleSynthRectifier): float32 =
  return 128.0
method draw*(module: ModuleSynthRectifier, infos: var SynthInfos, modifiable: bool, eventList: var EventList): EventModuleGui =
  discard miniOsc("ABCD", module.waveDisplay.addr)
  igSetNextItemWidth(128)
  centerElementX(128)
  sliderScalar[uint8]("##posOrNeg", IgDataType.U8, module.posOrNeg.addr, 0, 1, modes[module.posOrNeg], IgSliderFlags.AlwaysClamp)
  .treatAction(eventList, fmt"Rectifier: Rectifier type set to {modes[module.posOrNeg]}")
  const KNOB_SIZE = 64
  centerElementX(KNOB_SIZE)
  knobFloat[float32]("Rect.\nLevel", module.rectLevel.peak.addr, -1, 1, 10, size = KNOB_SIZE)
  .treatAction(eventList, fmt"Rectifier: Rectifier level set to {module.rectLevel.peak}")
  if(advancedSettingsButton()):
    module.popupOpened = true
    return GUI_OPEN_POPUP
  # igText(fmt"inputs: {module.inputs}")
  # igEndChild()

method `popupTitle`*(module: ModuleSynthRectifier): string =
  return POPUP_NAME

method `title`*(module: ModuleSynthRectifier): Text =
  return moduleTitles[MODULE_RECTIFIER]
