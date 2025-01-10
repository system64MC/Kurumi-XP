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

const NB_MASKS = 32

type
  ModuleSynthAmpMask* = ref object of ModuleSynthGeneric
    masks: array[NB_MASKS, bool]
    maskLevel: Adsr
  ModuleSynthAmpMaskSerialize* = object of ModuleSynthGenericSerialize

proc summon*(_: typedesc[ModuleSynthAmpMask], position: Vec2[float32]): ModuleSynthAmpMask =
  result = ModuleSynthAmpMask(inputs: @[
  PinConnection(moduleIndex: -1, pinIndex: -1), 
  ], outputs: @[PinConnection(moduleIndex: -1, pinIndex: -1)], position: position)
  for m in result.masks.mitems: m = true

method synthesize*(module: ModuleSynthAmpMask, x: float64, pin: int, moduleList: array[MAX_MODULES, ModuleSynthGeneric], synthInfos: SynthInfos, renderWidth: int): float64 =
  let moduleA = if(module.inputs[0].moduleIndex > -1): moduleList[module.inputs[0].moduleIndex] else: return 0
  if(moduleA == nil): return 0

  result = if(module.masks[(x * NB_MASKS).int]): moduleA.synthesize(moduloFix(x, 1.0), module.inputs[0].pinIndex, moduleList, synthInfos, renderWidth).flushToZero() else: module.maskLevel.doAdsr(synthInfos.macroFrame).flushToZero()

method draw*(module: ModuleSynthAmpMask, infos: var SynthInfos, modifiable: bool, eventList: var EventList): EventModuleGui =
  centerElementX(128)
  discard miniOsc("ABCD", module.waveDisplay.addr)
  igSetNextItemWidth(128)
  centerElementX(128)
  sliderFloat32("##Level".cstring, module.maskLevel.peak.addr, -1.0f, 1.0f, "Level: %.4f".cstring, IgSliderFlags.None)
  .treatAction(eventList, fmt"AmpMask: Level set to {module.maskLevel.peak}")
  centerElementX((igGetFontSize() + igGetStyle().FramePadding.x * 2) * 8 + 7 * 2)
  igBeginGroup()
  for i in 0..<NB_MASKS:
    checkbox(fmt"##Mask{i}".cstring, module.masks[i].addr)
    .treatAction(eventList, fmt"AmpMask: Mask {i} set to {module.masks[i]}")
    if((i + 1) mod 8 != 0):
      igSameLine(0, 2)
  igEndGroup()
  if(advancedSettingsButton()):
    module.popupOpened = true
    return GUI_OPEN_POPUP

const POPUP_NAME = "Amplifier: Advanced Settings"
import ../../gui/envelopes/guiEnvelopesMain
method drawPopup*(module: ModuleSynthAmpMask, infos: var SynthInfos, eventList: var EventList): void =
  moduleModal(POPUP_NAME, module.popupOpened.addr):
    igBeginTabBar("##TabBar", 0)
    igPushFont(FONT_AUDIO.getFont())
    if(igBeginTabItem(fmt"{ICON_FAD_ADSR} Mask Level envelope", nil, 0)):
      module.maskLevel.draw(module, infos, 0, 1, eventList, moduleTitles[MODULE_OSCILLATOR].data, "Mask Level")
      igEndTabItem()
    igPopFont()
    igEndTabBar()

method `popupTitle`*(module: ModuleSynthAmpMask): string =
  return POPUP_NAME

method `title`*(module: ModuleSynthAmpMask): Text =
  return moduleTitles[MODULE_AMPMASK]

method `contentWidth`*(module: ModuleSynthAmpMask): float32 =
  return 128.0 + 32.0