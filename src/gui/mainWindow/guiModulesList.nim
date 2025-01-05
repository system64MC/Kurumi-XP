import std/[strutils, math]
import nimgl/[opengl,glfw]

import imguin/[glfw_opengl,cimgui]

import ../../synthesizer/modules/modulesEnum
import ../../systemFonts
import ../widgets

var moduleToSummon: ModuleType

const BUTTON_SIZE = ImVec2(x: 128, y: 64)
const BUTTON_SPACING = 32
proc dragAndDropButton*(moduleType: ModuleType) =
  withFont(moduleTitles[moduleType].bank):
    igButton(moduleTitles[moduleType].data.cstring, BUTTON_SIZE)
  if(igBeginDragDropSource(ImGuiDragDropFlags_SourceAllowNullID.cint)):
    moduleToSummon = moduleType
    withFont(moduleTitles[moduleType].bank):
      igButton(moduleTitles[moduleType].data.cstring, BUTTON_SIZE)
    igSetDragDropPayload("modulesList", moduleToSummon.addr, sizeof(typeof(moduleToSummon)).csize_t, 0)
    igEndDragDropSource()

proc drawModulesList*() =
  var availlableSpace: ImVec2
  igGetContentRegionAvail(availlableSpace.addr)
  if(igBeginChild_Str("modulesView", ImVec2(x: availlableSpace.x - igGetStyle().ItemSpacing.x, y: availlableSpace.y), ImGui_ChildFlags_Borders.cint, 0)):
    for t in MODULE_OSCILLATOR..<MODULE_END:
      if((t.int and 1) == 1):
        igSameLine(0, BUTTON_SPACING)
      else: centerElementX(BUTTON_SIZE.x * 2 + BUTTON_SPACING)
      dragAndDropButton(t)
    igEndChild()