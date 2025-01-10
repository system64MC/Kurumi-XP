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
  ModuleSynthExpMod* = ref object of ModuleSynthGeneric
  ModuleSynthExpModSerialize* = object of ModuleSynthGenericSerialize

proc summon*(_: typedesc[ModuleSynthExpMod], position: Vec2[float32]): ModuleSynthExpMod =
  return ModuleSynthExpMod(inputs: @[PinConnection(moduleIndex: -1, pinIndex: -1), PinConnection(moduleIndex: -1, pinIndex: -1)], outputs: @[PinConnection(moduleIndex: -1, pinIndex: -1)], position: position)

method synthesize*(module: ModuleSynthExpMod, x: float64, pin: int, moduleList: array[MAX_MODULES, ModuleSynthGeneric], synthInfos: SynthInfos, renderWidth: int): float64 =
  let moduleA = if(module.inputs[0].moduleIndex > -1): moduleList[module.inputs[0].moduleIndex] else: return 0
  let moduleB = if(module.inputs[1].moduleIndex > -1): moduleList[module.inputs[1].moduleIndex] else: nil

  let base = moduleA.synthesize(moduloFix(x, 1.0), module.inputs[0].pinIndex, moduleList, synthInfos, renderWidth)
  let exp = if(moduleB == nil): 1.0 else: moduleB.synthesize(moduloFix(x, 1.0), module.inputs[1].pinIndex, moduleList, synthInfos, renderWidth)

  return pow(abs(base), abs(exp)).copySign(base).flushToZero()

method draw*(module: ModuleSynthExpMod, infos: var SynthInfos, modifiable: bool, eventList: var EventList): EventModuleGui =
  discard miniOsc("ABCD", module.waveDisplay.addr)
  # igText(fmt"inputs: {module.inputs}")
  # igEndChild()

method `title`*(module: ModuleSynthExpMod): Text =
  return moduleTitles[MODULE_EXP_MOD]

method `contentWidth`*(module: ModuleSynthExpMod): float32 =
  return 128.0