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
  ModuleSynthAmplifier* = ref object of ModuleSynthGeneric
    amp: Adsr = Adsr(peak: 1.0)
  ModuleSynthAmplifierSerialize* = object of ModuleSynthGenericSerialize

proc summon*(_: typedesc[ModuleSynthAmplifier], position: Vec2[float32]): ModuleSynthAmplifier =
  return ModuleSynthAmplifier(inputs: @[PinConnection(moduleIndex: -1, pinIndex: -1)], outputs: @[PinConnection(moduleIndex: -1, pinIndex: -1)], position: position)

method synthesize*(module: ModuleSynthAmplifier, x: float64, pin: int, moduleList: array[MAX_MODULES, ModuleSynthGeneric], synthInfos: SynthInfos): float64 =
  if(module.inputs[0].moduleIndex < 0): return 0
  let moduleA = moduleList[module.inputs[0].moduleIndex]
  if(moduleA == nil): return 0
  else: moduleA.synthesize(moduloFix(x, 1.0), module.inputs[0].pinIndex, moduleList, synthInfos) * module.amp.doAdsr(synthInfos.macroFrame)


const POPUP_NAME = "Amplifier: Advanced Settings"
import ../../gui/envelopes/guiEnvelopesMain
method drawPopup*(module: ModuleSynthAmplifier, infos: var SynthInfos, eventList: var EventList): void =
  moduleModal(POPUP_NAME, module.popupOpened.addr):
    igBeginTabBar("##TabBar", 0)
    igPushFont(FONT_AUDIO.getFont())
    if(igBeginTabItem(fmt"{ICON_FAD_ADSR} Amp. envelope", nil, 0)):
      module.amp.draw(module, infos, 0, 1, eventList, moduleTitles[MODULE_OSCILLATOR].data, "Phase")
      igEndTabItem()
    igPopFont()
    igEndTabBar()

method `contentWidth`*(module: ModuleSynthAmplifier): float32 =
  return 128.0
method draw*(module: ModuleSynthAmplifier, infos: var SynthInfos, modifiable: bool, eventList: var EventList): EventModuleGui =
  discard miniOsc("ABCD", module.waveDisplay.addr)
  const KNOB_SIZE = 64
  centerElementX(KNOB_SIZE)
  knobFloat[float32]("Amp", module.amp.peak.addr, 0.0f, 4.0f, 10, size = KNOB_SIZE)
  .treatAction(eventList, fmt"Amplifier: Amp set to {module.amp.peak}")
  if(advancedSettingsButton()):
    module.popupOpened = true
    return GUI_OPEN_POPUP
  # igText(fmt"inputs: {module.inputs}")
  # igEndChild()

method `popupTitle`*(module: ModuleSynthAmplifier): string =
  return POPUP_NAME

method `title`*(module: ModuleSynthAmplifier): Text =
  return moduleTitles[MODULE_AMPLIFIER]
