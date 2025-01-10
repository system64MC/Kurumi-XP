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
  ModuleSynthMixer* = ref object of ModuleSynthGeneric
  ModuleSynthMixerSerialize* = object of ModuleSynthGenericSerialize

proc summon*(_: typedesc[ModuleSynthMixer], position: Vec2[float32]): ModuleSynthMixer =
  return ModuleSynthMixer(inputs: @[
  PinConnection(moduleIndex: -1, pinIndex: -1), 
  PinConnection(moduleIndex: -1, pinIndex: -1), 
  PinConnection(moduleIndex: -1, pinIndex: -1), 
  PinConnection(moduleIndex: -1, pinIndex: -1), 
  PinConnection(moduleIndex: -1, pinIndex: -1), 
  PinConnection(moduleIndex: -1, pinIndex: -1), 
  PinConnection(moduleIndex: -1, pinIndex: -1), 
  PinConnection(moduleIndex: -1, pinIndex: -1)
  ], outputs: @[PinConnection(moduleIndex: -1, pinIndex: -1)], position: position)

method synthesize*(module: ModuleSynthMixer, x: float64, pin: int, moduleList: array[MAX_MODULES, ModuleSynthGeneric], synthInfos: SynthInfos, renderWidth: int): float64 =
  var output = 0.0

  for link in module.inputs:
    if(link.moduleIndex > -1):
      let module = moduleList[link.moduleIndex]
      if(module == nil): continue
      output += module.synthesize(moduloFix(x, 1.0), link.pinIndex, moduleList, synthInfos, renderWidth)

  return output.flushToZero()

method draw*(module: ModuleSynthMixer, infos: var SynthInfos, modifiable: bool, eventList: var EventList): EventModuleGui =
  discard miniOsc("ABCD", module.waveDisplay.addr)
  # igText(fmt"inputs: {module.inputs}")
  # igEndChild()

method `title`*(module: ModuleSynthMixer): Text =
  return moduleTitles[MODULE_MIXER]

method `contentWidth`*(module: ModuleSynthMixer): float32 =
  return 128.0