import ../../globals
import ../../utils
import ../../synthesizer/synthInfos
import ../../events
import ../../gui/widgets
import ../../maths
import ../../systemFonts
import ../../fonts/IconsFontAwesome6
import ../../fonts/IconsFontAudio
import moduleSynthGeneric
import modulesEnum
import math

import imguin/[glfw_opengl,cimgui]
import strformat

type
  WaveFoldType* = enum
    SINE = 0
    LINFOLD = 1
    OVERFLOW = 2

  ModuleSynthWaveFolder* = ref object of ModuleSynthGeneric
    mode: uint8 = 0
  ModuleSynthWaveFolderSerialize* = object of ModuleSynthGenericSerialize

proc summon*(_: typedesc[ModuleSynthWaveFolder], position: Vec2[float32]): ModuleSynthWaveFolder =
  return ModuleSynthWaveFolder(inputs: @[PinConnection(moduleIndex: -1, pinIndex: -1)], outputs: @[PinConnection(moduleIndex: -1, pinIndex: -1)], position: position)

proc linFold(x: float64): float64 =
  let a = x * 0.25 + 0.75
  let r = moduloFix(a, 1)
  return abs(r * -4.0 + 2.0) - 1.0

proc vital(x: float64): float64 =
  let a = x * 0.25 + 0.75
  let r = moduloFix(a, 1)
  return abs(r * -4.0 + 2.0) - 1.0

proc overFlow(x: float64): float64 =
  if(x <= 1 and x >= -1): return x
  return moduloFix(x + 1, 2) - 1

proc waveFolding(x: float64, waveFoldType: uint8): float64 =
  case waveFoldType.WaveFoldType:
  of WaveFoldType.SINE: return sin(x)
  of WaveFoldType.LINFOLD: return linFold(x)
  of WaveFoldType.OVERFLOW: return overFlow(x)


method synthesize*(module: ModuleSynthWaveFolder, x: float64, pin: int, moduleList: array[MAX_MODULES, ModuleSynthGeneric], synthInfos: SynthInfos, renderWidth: int): float64 =
  if(module.inputs[0].moduleIndex < 0): return 0
  let moduleA = moduleList[module.inputs[0].moduleIndex]
  if(moduleA == nil): return 0
  result = moduleA.synthesize(moduloFix(x, 1.0), module.inputs[0].pinIndex, moduleList, synthInfos, renderWidth)
  
  
  result = result.waveFolding(module.mode).flushToZero()


const modes = ["Sine".cstring, "LinFold", "Overflow"]
method `contentWidth`*(module: ModuleSynthWaveFolder): float32 =
  return 128.0
method draw*(module: ModuleSynthWaveFolder, infos: var SynthInfos, modifiable: bool, eventList: var EventList): EventModuleGui =
  discard miniOsc("ABCD", module.waveDisplay.addr)
  igSetNextItemWidth(128)
  centerElementX(128)
  sliderScalar[uint8]("##posOrNeg", IgDataType.U8, module.mode.addr, 0, modes.len - 1, modes[module.mode], IgSliderFlags.AlwaysClamp)
  .treatAction(eventList, fmt"WaveFolder: Rectifier type set to {modes[module.mode]}")

method `title`*(module: ModuleSynthWaveFolder): Text =
  return moduleTitles[MODULE_WAVEFOLDER]
