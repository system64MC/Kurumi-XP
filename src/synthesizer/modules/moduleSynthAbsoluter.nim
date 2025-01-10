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
  ModuleSynthAbsoluter* = ref object of ModuleSynthGeneric
  ModuleSynthAbsoluterSerialize* = object of ModuleSynthGenericSerialize

proc summon*(_: typedesc[ModuleSynthAbsoluter], position: Vec2[float32]): ModuleSynthAbsoluter =
  return ModuleSynthAbsoluter(inputs: @[
  PinConnection(moduleIndex: -1, pinIndex: -1), 
  ], outputs: @[PinConnection(moduleIndex: -1, pinIndex: -1)], position: position)

method synthesize*(module: ModuleSynthAbsoluter, x: float64, pin: int, moduleList: array[MAX_MODULES, ModuleSynthGeneric], synthInfos: SynthInfos, renderWidth: int): float64 =
  let moduleA = if(module.inputs[0].moduleIndex > -1): moduleList[module.inputs[0].moduleIndex] else: return 0
  if(moduleA == nil): return 0

  result = moduleA.synthesize(moduloFix(x, 1.0), module.inputs[0].pinIndex, moduleList, synthInfos, renderWidth).flushToZero().abs()

method draw*(module: ModuleSynthAbsoluter, infos: var SynthInfos, modifiable: bool, eventList: var EventList): EventModuleGui =
  discard miniOsc("ABCD", module.waveDisplay.addr)
  # igText(fmt"inputs: {module.inputs}")
  # igEndChild()

method `title`*(module: ModuleSynthAbsoluter): Text =
  return moduleTitles[MODULE_ABSOLUTER]

method `contentWidth`*(module: ModuleSynthAbsoluter): float32 =
  return 128.0