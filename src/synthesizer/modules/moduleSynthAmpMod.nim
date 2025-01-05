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
  ModuleSynthAmpMod* = ref object of ModuleSynthGeneric
  ModuleSynthAmpModSerialize* = object of ModuleSynthGenericSerialize

proc summon*(_: typedesc[ModuleSynthAmpMod], position: Vec2[float32]): ModuleSynthAmpMod =
  return ModuleSynthAmpMod(inputs: @[PinConnection(moduleIndex: -1, pinIndex: -1), PinConnection(moduleIndex: -1, pinIndex: -1)], outputs: @[PinConnection(moduleIndex: -1, pinIndex: -1)], position: position)

method synthesize*(module: ModuleSynthAmpMod, x: float64, pin: int, moduleList: array[MAX_MODULES, ModuleSynthGeneric], synthInfos: SynthInfos): float64 =
  let moduleB = if(module.inputs[1].moduleIndex > -1): moduleList[module.inputs[1].moduleIndex] else: return 0
  let moduleA = if(module.inputs[0].moduleIndex > -1): moduleList[module.inputs[0].moduleIndex] else: return 0

  if(moduleA == nil or moduleB == nil): return 0

  let a = moduleA.synthesize(moduloFix(x, 1.0), module.inputs[0].pinIndex, moduleList, synthInfos)
  let b = moduleB.synthesize(moduloFix(x, 1.0), module.inputs[1].pinIndex, moduleList, synthInfos)
  return a * b

method draw*(module: ModuleSynthAmpMod, infos: var SynthInfos, modifiable: bool, eventList: var EventList): EventModuleGui =
  discard miniOsc("ABCD", module.waveDisplay.addr)
  # igText(fmt"inputs: {module.inputs}")
  # igEndChild()

method `title`*(module: ModuleSynthAmpMod): Text =
  return moduleTitles[MODULE_AMP_MOD]

method `contentWidth`*(module: ModuleSynthAmpMod): float32 =
  return 128.0