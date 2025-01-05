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
  ModuleSynthPhase* = ref object of ModuleSynthGeneric
    phase: Adsr = Adsr(peak: 0.0)
    detune: int8 = 0
  ModuleSynthPhaseSerialize* = object of ModuleSynthGenericSerialize

proc summon*(_: typedesc[ModuleSynthPhase], position: Vec2[float32]): ModuleSynthPhase =
  return ModuleSynthPhase(inputs: @[PinConnection(moduleIndex: -1, pinIndex: -1)], outputs: @[PinConnection(moduleIndex: -1, pinIndex: -1)], position: position)

method getPhase(module: ModuleSynthPhase, mac: int32, macLen: int32): float64 {.base.} =
    var mac = mac.float64
    var macLen = macLen.float64

    # Anti-divide by 0
    if(macLen < 1): macLen = 1
    return mac.float64 / (macLen) * module.detune.float64

method synthesize*(module: ModuleSynthPhase, x: float64, pin: int, moduleList: array[MAX_MODULES, ModuleSynthGeneric], synthInfos: SynthInfos): float64 =
  if(module.inputs[0].moduleIndex < 0): return 0
  let moduleA = moduleList[module.inputs[0].moduleIndex]
  if(moduleA == nil): return 0 else: return moduleA.synthesize(moduloFix(x + module.phase.doAdsr(synthInfos.macroFrame) + module.getPhase(synthInfos.macroFrame, synthInfos.macroLen), 1.0), module.inputs[0].pinIndex, moduleList, synthInfos)


const POPUP_NAME = "Phase: Advanced Settings"
import ../../gui/envelopes/guiEnvelopesMain
method `popupTitle`*(module: ModuleSynthPhase): string =
  return POPUP_NAME
method drawPopup*(module: ModuleSynthPhase, infos: var SynthInfos, eventList: var EventList): void =
  moduleModal(POPUP_NAME, module.popupOpened.addr):
    igBeginTabBar("##TabBar", 0)
    igPushFont(FONT_AUDIO.getFont())
    if(igBeginTabItem(fmt"{ICON_FAD_ADSR} Phase envelope", nil, 0)):
      module.phase.draw(module, infos, 0, 1, eventList, moduleTitles[MODULE_OSCILLATOR].data, "Phase")
      igEndTabItem()
    igPopFont()
    igEndTabBar()

method `contentWidth`*(module: ModuleSynthPhase): float32 =
  return 128.0
method draw*(module: ModuleSynthPhase, infos: var SynthInfos, modifiable: bool, eventList: var EventList): EventModuleGui =
  discard miniOsc("ABCD", module.waveDisplay.addr)
  const MAX_EXP = 16
  igSetNextItemWidth(128)
  sliderFloat32("##Phase".cstring, module.phase.peak.addr, 0.0f, 1.0f, "Phase: %.4f".cstring, IgSliderFlags.None)
  .treatAction(eventList, fmt"Phase: Phase set to {module.phase.peak}")
  const KNOB_SIZE = 64
  igSetCursorPos(ImVec2(x: igGetCursorPosX() + (module.contentWidth - (KNOB_SIZE)) / 2, y: igGetCursorPosY()))
  knobInteger[int8]("DT.", addr module.detune, -32, 32, 0.cint)
  .treatAction(eventList, fmt"Oscillator: Detune set to {module.detune}")
  if(advancedSettingsButton()):
    module.popupOpened = true
    return GUI_OPEN_POPUP
  
  # igText(fmt"inputs: {module.inputs}")
  # igEndChild()

method `title`*(module: ModuleSynthPhase): Text =
  return moduleTitles[MODULE_PHASE]
