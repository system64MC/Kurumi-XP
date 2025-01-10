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

const NB_MASKS = 16

type
  ModuleSynthPhaseMask* = ref object of ModuleSynthGeneric
    mask: uint16 = 0xFFFF
    maskLevel: Adsr
  ModuleSynthPhaseMaskSerialize* = object of ModuleSynthGenericSerialize

proc summon*(_: typedesc[ModuleSynthPhaseMask], position: Vec2[float32]): ModuleSynthPhaseMask =
  return ModuleSynthPhaseMask(inputs: @[
  PinConnection(moduleIndex: -1, pinIndex: -1), 
  ], outputs: @[PinConnection(moduleIndex: -1, pinIndex: -1)], position: position)

method synthesize*(module: ModuleSynthPhaseMask, x: float64, pin: int, moduleList: array[MAX_MODULES, ModuleSynthGeneric], synthInfos: SynthInfos, renderWidth: int): float64 =
  let moduleA = if(module.inputs[0].moduleIndex > -1): moduleList[module.inputs[0].moduleIndex] else: return 0
  if(moduleA == nil): return 0
  let x2 = ((moduloFix(x, 1.0) * 0x1_00_00).uint16 and module.mask).float64 / 0x1_00_00.float64
  result = moduleA.synthesize(moduloFix(x2, 1.0), module.inputs[0].pinIndex, moduleList, synthInfos, renderWidth).flushToZero()

method draw*(module: ModuleSynthPhaseMask, infos: var SynthInfos, modifiable: bool, eventList: var EventList): EventModuleGui =
  centerElementX(128)
  discard miniOsc("ABCD", module.waveDisplay.addr)
  centerElementX((igGetFontSize() + igGetStyle().FramePadding.x * 2) * 8 + 7 * 2)
  igBeginGroup()
  for i in 0..<NB_MASKS:
    var value: bool = ((module.mask shr (15 - i)) and 1).bool
    checkbox(fmt"##Mask{i}".cstring, value.addr)
    .treatAction(eventList, fmt"PhaseMask: Mask {i} set to {value}")
    
    if(value):
      module.mask = module.mask or (1 shl (15 - i)).uint16
    else:
      module.mask = module.mask and (not (1 shl (15 - i)).uint16)
    if((i + 1) mod 8 != 0):
      igSameLine(0, 2)
  igEndGroup()

method `title`*(module: ModuleSynthPhaseMask): Text =
  return moduleTitles[MODULE_PHASEMASK]

method `contentWidth`*(module: ModuleSynthPhaseMask): float32 =
  return 128.0 + 32.0