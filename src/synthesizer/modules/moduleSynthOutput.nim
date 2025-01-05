import ../../globals
import ../../utils
import ../../synthesizer/synthInfos
import ../../events
import ../../gui/widgets
import ../../systemFonts
import ../../maths
import moduleSynthGeneric
import modulesEnum
import math

import imguin/[glfw_opengl,cimgui]
import strformat

type
  ModuleSynthOutput* = ref object of ModuleSynthGeneric
  ModuleSynthOutputSerialize* = object of ModuleSynthGenericSerialize

proc summon*(_: typedesc[ModuleSynthOutput]): ModuleSynthOutput =
  return ModuleSynthOutput(inputs: @[PinConnection(moduleIndex: -1, pinIndex: -1)], outputs: @[])

method synthesize*(module: ModuleSynthOutput, x: float64, pin: int, moduleList: array[MAX_MODULES, ModuleSynthGeneric], synthInfos: SynthInfos): float64 =
  if(module.inputs[0].moduleIndex < 0): return 0
  let moduleA = moduleList[module.inputs[0].moduleIndex]
  if(moduleA == nil): return 0
  else: moduleA.synthesize(moduloFix(x, 1.0), module.inputs[0].pinIndex, moduleList, synthInfos).flushToZero()

method draw*(module: ModuleSynthOutput, infos: var SynthInfos, modifiable: bool, eventList: var EventList): EventModuleGui =
  discard miniOsc("ABCD", module.waveDisplay.addr)
  # igText(fmt"inputs: {module.inputs}")
  # igEndChild()

method `title`*(module: ModuleSynthOutput): Text =
  return moduleTitles[MODULE_OUTPUT]

method `contentWidth`*(module: ModuleSynthOutput): float32 =
  return 128.0