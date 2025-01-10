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
  ModuleSynthPhaseMod* = ref object of ModuleSynthGeneric
  ModuleSynthPhaseModSerialize* = object of ModuleSynthGenericSerialize

proc summon*(_: typedesc[ModuleSynthPhaseMod], position: Vec2[float32]): ModuleSynthPhaseMod =
  return ModuleSynthPhaseMod(inputs: @[PinConnection(moduleIndex: -1, pinIndex: -1), PinConnection(moduleIndex: -1, pinIndex: -1)], outputs: @[PinConnection(moduleIndex: -1, pinIndex: -1)], position: position)

method synthesize*(module: ModuleSynthPhaseMod, x: float64, pin: int, moduleList: array[MAX_MODULES, ModuleSynthGeneric], synthInfos: SynthInfos, renderWidth: int): float64 =
  let moduleB = if(module.inputs[1].moduleIndex > -1): moduleList[module.inputs[1].moduleIndex] else: return 0
  let moduleA = if(module.inputs[0].moduleIndex > -1): moduleList[module.inputs[0].moduleIndex] else: nil

  let modulation = if(moduleA == nil): 0.0 else: moduleA.synthesize(moduloFix(x, 1.0), module.inputs[0].pinIndex, moduleList, synthInfos, renderWidth)

  return moduleB.synthesize(moduloFix(x + modulation, 1.0), module.inputs[1].pinIndex, moduleList, synthInfos, renderWidth).flushToZero()

method draw*(module: ModuleSynthPhaseMod, infos: var SynthInfos, modifiable: bool, eventList: var EventList): EventModuleGui =
  discard miniOsc("ABCD", module.waveDisplay.addr)
  # igText(fmt"inputs: {module.inputs}")
  # igEndChild()

method `title`*(module: ModuleSynthPhaseMod): Text =
  return moduleTitles[MODULE_PHASE_MOD]

method `contentWidth`*(module: ModuleSynthPhaseMod): float32 =
  return 128.0