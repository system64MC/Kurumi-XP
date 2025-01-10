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
  ModuleSynthInverter* = ref object of ModuleSynthGeneric
  ModuleSynthInverterSerialize* = object of ModuleSynthGenericSerialize

proc summon*(_: typedesc[ModuleSynthInverter], position: Vec2[float32]): ModuleSynthInverter =
  return ModuleSynthInverter(inputs: @[
  PinConnection(moduleIndex: -1, pinIndex: -1), 
  ], outputs: @[PinConnection(moduleIndex: -1, pinIndex: -1)], position: position)

method synthesize*(module: ModuleSynthInverter, x: float64, pin: int, moduleList: array[MAX_MODULES, ModuleSynthGeneric], synthInfos: SynthInfos, renderWidth: int): float64 =
  let moduleA = if(module.inputs[0].moduleIndex > -1): moduleList[module.inputs[0].moduleIndex] else: return 0
  if(moduleA == nil): return 0

  result = -moduleA.synthesize(moduloFix(x, 1.0), module.inputs[0].pinIndex, moduleList, synthInfos, renderWidth).flushToZero()

method draw*(module: ModuleSynthInverter, infos: var SynthInfos, modifiable: bool, eventList: var EventList): EventModuleGui =
  discard miniOsc("ABCD", module.waveDisplay.addr)
  # igText(fmt"inputs: {module.inputs}")
  # igEndChild()

method `title`*(module: ModuleSynthInverter): Text =
  return moduleTitles[MODULE_INVERTER]

method `contentWidth`*(module: ModuleSynthInverter): float32 =
  return 128.0