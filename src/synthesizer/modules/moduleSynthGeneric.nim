import ../../globals
import ../../utils
import ../synthInfos
import modulesEnum
import math
import ../../events
import ../../maths
import ../../systemFonts

type
  ModuleSynthGeneric* = ref object of RootObj
    inputs*  : seq[PinConnection]
    outputs* : seq[PinConnection]
    update*: bool = true
    waveDisplay*: array[MODULE_DISPLAY_RESOLUTION, float32]
    position*: Vec2[float32] = Vec2[float32](x: 0, y: 0)

    popupOpened*: bool = false
    isMaxed* = true
    #isHovered: bool = false

  ModuleSynthGenericSerialize* = object of RootObj
    inputs*: seq[PinConnection]
    outputs*: seq[PinConnection]

method synthesize*(module: ModuleSynthGeneric, x: float64, pin: int, moduleList: array[MAX_MODULES, ModuleSynthGeneric], synthInfos: SynthInfos, renderWidth: int): float64 {.base, gcsafe.} =
  return x

method updateDisplay*(module: ModuleSynthGeneric, moduleList: array[MAX_MODULES, ModuleSynthGeneric], synthInfos: SynthInfos, renderWidth: int) {.base, gcsafe.} =
  for i in 0..<MODULE_DISPLAY_RESOLUTION.int:
    let sample = module.synthesize(i.float64 / MODULE_DISPLAY_RESOLUTION, 0, moduleList, synthInfos, MODULE_DISPLAY_RESOLUTION)
    module.waveDisplay[i] = sample.float32
  return

method drawPopup*(module: ModuleSynthGeneric, infos: var SynthInfos, eventList: var EventList): void {.base.} =
  return

method draw*(module: ModuleSynthGeneric, infos: var SynthInfos, modifiable: bool, eventList: var EventList): EventModuleGui {.base.} =
  return

method `title`*(module: ModuleSynthGeneric): Text {.base.} =
  return moduleTitles[MODULE_NULL]

method `popupTitle`*(module: ModuleSynthGeneric): string {.base.} =
  return ""

method `contentWidth`*(module: ModuleSynthGeneric): float32 {.base.} =
  return 256.0