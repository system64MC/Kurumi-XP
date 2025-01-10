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
  ModuleSynthSILM* = ref object of ModuleSynthGeneric
    mode: uint8 = 0
  ModuleSynthSILMSerialize* = object of ModuleSynthGenericSerialize

proc summon*(_: typedesc[ModuleSynthSILM], position: Vec2[float32]): ModuleSynthSILM =
  return ModuleSynthSILM(inputs: @[PinConnection(moduleIndex: -1, pinIndex: -1), PinConnection(moduleIndex: -1, pinIndex: -1)], outputs: @[PinConnection(moduleIndex: -1, pinIndex: -1)], position: position)

func c(x, y: float64): float64 =
  return min(max(x, y), -min(x, y))

func c2(x1, y1, x2, y2: float64): float64 =
  return min(max(x1, y1), -min(x2, y2))

const silmFuncs* = [
  func(x, y: float64): float64 = return c(x, y),
  func(x, y: float64): float64 = return min(max(x, y), -min(max(x, y), c(x, y))),
  func(x, y: float64): float64 = return min(x, -c(x, y)),
  func(x, y: float64): float64 = return c2(x, y, c(x, y), -y),
  func(x, y: float64): float64 = return c2(x, c(x, y), c(x, y), y),
  func(x, y: float64): float64 = return c(x + y, x - y),
  func(x, y: float64): float64 = return x - min(max(y, min(x, 0)), max(x, 0)),
  func(x, y: float64): float64 = return min(y, max(0, min(y + x, y - x))),
  func(x, y: float64): float64 = return min(max(y, y + x), max(0, min(y + x, y - x))),
  func(x, y: float64): float64 = return max(min(max(-x, y), y - x), min(x + y, -(x + y)))         
]


method synthesize*(module: ModuleSynthSILM, x: float64, pin: int, moduleList: array[MAX_MODULES, ModuleSynthGeneric], synthInfos: SynthInfos, renderWidth: int): float64 =
  var moduleA: ModuleSynthGeneric = nil
  var moduleB: ModuleSynthGeneric = nil

  if(module.inputs[0].moduleIndex > -1):
    moduleA = moduleList[module.inputs[0].moduleIndex]
  if(module.inputs[1].moduleIndex > -1):
    moduleB = moduleList[module.inputs[1].moduleIndex]
  
  if(moduleA == nil and moduleB == nil): return 0

  let a = if(moduleA != nil): moduleA.synthesize(x, module.inputs[0].pinIndex, moduleList, synthInfos, renderWidth) else: 0.0
  let b = if(moduleB != nil): moduleB.synthesize(x, module.inputs[1].pinIndex, moduleList, synthInfos, renderWidth) else: 0.0

  return silmFuncs[module.mode](a, b).flushToZero()


method draw*(module: ModuleSynthSILM, infos: var SynthInfos, modifiable: bool, eventList: var EventList): EventModuleGui =
  discard miniOsc("ABCD", module.waveDisplay.addr)
  const MAX_EXP = 16
  const KNOB_SIZE = 64
  centerElementX(KNOB_SIZE)
  knobInteger[uint8]("Mode", module.mode.addr, 0, silmFuncs.len.uint8 - 1, silmFuncs.len.int32, size = KNOB_SIZE, clip_min = 0, clip_max = silmFuncs.len.uint8 - 1, clip = true)
  .treatAction(eventList, fmt"SILM: Mode set to {module.mode}")

method `title`*(module: ModuleSynthSILM): Text =
  return moduleTitles[MODULE_SILM]

method `contentWidth`*(module: ModuleSynthSILM): float32 =
  return 128.0