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
  ModuleSynthSplitter* = ref object of ModuleSynthGeneric
  ModuleSynthSplitterSerialize* = object of ModuleSynthGenericSerialize

proc summon*(_: typedesc[ModuleSynthSplitter], position: Vec2[float32]): ModuleSynthSplitter =
  return ModuleSynthSplitter(inputs: @[PinConnection(moduleIndex: -1, pinIndex: -1),], outputs: @[
    PinConnection(moduleIndex: -1, pinIndex: -1),
    PinConnection(moduleIndex: -1, pinIndex: -1), 
    PinConnection(moduleIndex: -1, pinIndex: -1), 
    PinConnection(moduleIndex: -1, pinIndex: -1), 
    PinConnection(moduleIndex: -1, pinIndex: -1), 
    PinConnection(moduleIndex: -1, pinIndex: -1), 
    PinConnection(moduleIndex: -1, pinIndex: -1), 
    PinConnection(moduleIndex: -1, pinIndex: -1)
    ], position: position)

method synthesize*(module: ModuleSynthSplitter, x: float64, pin: int, moduleList: array[MAX_MODULES, ModuleSynthGeneric], synthInfos: SynthInfos): float64 =
  if(module.inputs[0].moduleIndex < 0): return 0
  let moduleA = moduleList[module.inputs[0].moduleIndex]
  if(moduleA == nil): return 0.0 else: return moduleA.synthesize(moduloFix(x, 1.0), module.inputs[0].pinIndex, moduleList, synthInfos)

method draw*(module: ModuleSynthSplitter, infos: var SynthInfos, modifiable: bool, eventList: var EventList): EventModuleGui =
  discard miniOsc("ABCD", module.waveDisplay.addr)
  # igText(fmt"inputs: {module.inputs}")
  # igEndChild()

method `title`*(module: ModuleSynthSplitter): Text =
  return moduleTitles[MODULE_SPLITTER]

method `contentWidth`*(module: ModuleSynthSplitter): float32 =
  return 128.0