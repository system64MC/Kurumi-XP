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
  ModuleSynthMiniMax* = ref object of ModuleSynthGeneric
    mode*: uint8 = 0
    
  ModuleSynthMiniMaxSerialize* = object of ModuleSynthGenericSerialize

proc summon*(_: typedesc[ModuleSynthMiniMax], position: Vec2[float32]): ModuleSynthMiniMax =
  return ModuleSynthMiniMax(inputs: @[PinConnection(moduleIndex: -1, pinIndex: -1), PinConnection(moduleIndex: -1, pinIndex: -1)], outputs: @[PinConnection(moduleIndex: -1, pinIndex: -1)], position: position)

method synthesize*(module: ModuleSynthMiniMax, x: float64, pin: int, moduleList: array[MAX_MODULES, ModuleSynthGeneric], synthInfos: SynthInfos, renderWidth: int): float64 =
  var moduleA: ModuleSynthGeneric = nil
  var moduleB: ModuleSynthGeneric = nil

  if(module.inputs[0].moduleIndex > -1):
    moduleA = moduleList[module.inputs[0].moduleIndex]
  if(module.inputs[1].moduleIndex > -1):
    moduleB = moduleList[module.inputs[1].moduleIndex]
  
  if(moduleA == nil and moduleB == nil): return 0

  let a = if(moduleA != nil): moduleA.synthesize(moduloFix(x, 1.0), module.inputs[0].pinIndex, moduleList, synthInfos, renderWidth) else: 0.0
  let b = if(moduleB != nil): moduleB.synthesize(moduloFix(x, 1.0), module.inputs[1].pinIndex, moduleList, synthInfos, renderWidth) else: 0.0

  case module.mode:
  of 0: return min(a, b)
  of 1: return max(a, b)
  else: return 0

const modeStrings = ["Min".cstring, "Max"]
method draw*(module: ModuleSynthMiniMax, infos: var SynthInfos, modifiable: bool, eventList: var EventList): EventModuleGui =
  discard miniOsc("ABCD", module.waveDisplay.addr)
  igSetNextItemWidth(128)
  sliderScalar[uint8]("##modeMiniMax", IgDataType.U8, module.mode.addr, 0, 1, fmt"Mode: {modeStrings[module.mode]}", IgSliderFlags.AlwaysClamp)
  .treatAction(eventList, fmt"MiniMax: Mode set to {modeStrings[module.mode]}")
  # igText(fmt"inputs: {module.inputs}")
  # igEndChild()

method `title`*(module: ModuleSynthMiniMax): Text =
  return moduleTitles[MODULE_MINIMAX]

method `contentWidth`*(module: ModuleSynthMiniMax): float32 =
  return 128.0