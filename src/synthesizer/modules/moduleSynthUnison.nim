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

#[
TODO : Fix detune bug when 
]#


type
  ModuleSynthUnison* = ref object of ModuleSynthGeneric
    unison: uint16 = 1
    unisonStart: Adsr = Adsr(peak: 0.0)
    affectedBySequence: bool = true
  ModuleSynthUnisonSerialize* = object of ModuleSynthGenericSerialize

proc summon*(_: typedesc[ModuleSynthUnison], position: Vec2[float32]): ModuleSynthUnison =
  return ModuleSynthUnison(inputs: @[PinConnection(moduleIndex: -1, pinIndex: -1)], outputs: @[PinConnection(moduleIndex: -1, pinIndex: -1)], position: position)


proc getPhase(unisonLevel: float64, mac: int32, macLen: int32, unisonStart: float, sequence: bool): float64 =
  var mac = mac.float64
  var macLen = macLen.float64
  let detune = pow(-1, unisonLevel + 1) * ceil(unisonLevel / 2)
  # Anti-divide by 0
  if(macLen < 1): macLen = 1
  return (if(sequence): (mac.float64 / (macLen) * detune) else: 0) + (unisonStart * detune)

method synthesize*(module: ModuleSynthUnison, x: float64, pin: int, moduleList: array[MAX_MODULES, ModuleSynthGeneric], synthInfos: SynthInfos): float64 =
  if(module.inputs[0].moduleIndex < 0): return 0
  let moduleA = moduleList[module.inputs[0].moduleIndex]
  if(moduleA == nil): 
    return 0.0
  else:
    if(module.unison < 1):
      return moduleA.synthesize(x, module.inputs[0].pinIndex, moduleList, synthInfos)
    var sum = 0.0
    var divider = 0.0
    for i in 0..module.unison.uint32:
      divider += 1.0
      sum += moduleA.synthesize(moduloFix(x + getPhase(i.float64, synthInfos.macroFrame, synthInfos.macroLen, module.unisonStart.doAdsr(synthInfos.macroFrame), module.affectedBySequence), 1.0), module.inputs[0].pinIndex, moduleList, synthInfos)

    return (sum / divider).flushToZero()


const POPUP_NAME = "Unison: Advanced Settings"
import ../../gui/envelopes/guiEnvelopesMain
method `popupTitle`*(module: ModuleSynthUnison): string =
  return POPUP_NAME
method drawPopup*(module: ModuleSynthUnison, infos: var SynthInfos, eventList: var EventList): void =
  moduleModal(POPUP_NAME, module.popupOpened.addr):
    igBeginTabBar("##TabBar", 0)
    igPushFont(FONT_AUDIO.getFont())
    if(igBeginTabItem(fmt"{ICON_FAD_ADSR} Unison start envelope", nil, 0)):
      module.unisonStart.draw(module, infos, 0, 1, eventList, moduleTitles[MODULE_OSCILLATOR].data, "Phase")
      igEndTabItem()
    igPopFont()
    igEndTabBar()

method `contentWidth`*(module: ModuleSynthUnison): float32 =
  return 128.0
method draw*(module: ModuleSynthUnison, infos: var SynthInfos, modifiable: bool, eventList: var EventList): EventModuleGui =
  discard miniOsc("ABCD", module.waveDisplay.addr)
  igSetNextItemWidth(128)
  checkBox("Sequence", module.affectedBySequence.addr)
  .treatAction(eventList, fmt"Unison: Sequence set to {module.affectedBySequence}")
  toolTip("If enabled, the unison is affected by the sequence.")
  const KNOB_SIZE = 64
  centerElementX(KNOB_SIZE * 2 + 2)
  igBeginGroup()
  knobInteger[uint16]("Unison", module.unison.addr, 1, 32, 0, size = KNOB_SIZE, clip_min = 0, clip_max = 256, clip = true)
  .treatAction(eventList, fmt"Unison: Unison set to {module.unison}")
  igSameLine(0, 2)
  knobFloat[float32]("Start", module.unisonStart.peak.addr, 0.0f, 1.0f, 0, size = KNOB_SIZE)
  .treatAction(eventList, fmt"Unison: Start set to {module.unisonStart.peak}")
  toolTip("Controls the starting state of the unison.")
  igEndGroup()
  if(advancedSettingsButton()):
    module.popupOpened = true
    return GUI_OPEN_POPUP

method `title`*(module: ModuleSynthUnison): Text =
  return moduleTitles[MODULE_UNISON]
