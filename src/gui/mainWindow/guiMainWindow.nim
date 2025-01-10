import std/[strutils, math]
import nimgl/[opengl,glfw]

import imguin/[glfw_opengl,cimgui]

import ../../globals
import ../../synthesizer/synth
import ../../synthesizer/modules/moduleSynthGeneric
import ../../app
import ../widgets

import ./[guiSynth, guiWavePreview, guiModulesList]

proc drawMainWindow*(app: KuruApp) =
  if(igBeginMainMenuBar()):
    menuBarHeight = igGetWindowHeight()
    if(igBeginMenu("File", true)):
      if(igMenuItemEx("Exit", nil, nil, false, true)):
        app.window.setWindowShouldClose(true)
      igEndMenu()
    if(igBeginMenu("Sound preview", true)):
      discard toggle("Enable sound preview", app.synth.previewOn.addr, ImVec2(x: 0, y: 0))
      discard knobFloat[float32]("Volume", app.synth.previewVolume.addr, 0.0f, 1.0f, 0, size = 64)
      igEndMenu()
    igEndMainMenuBar()

  var mainSize: ImVec2
  igGetContentRegionAvail(mainSize.addr)

  var vp = igGetMainViewport()
  let windowSize = ImVec2(x: vp.Size.x, y: vp.Size.y - menuBarHeight)
  let yPos = igGetCursorPosY() - igGetStyle().ItemInnerSpacing.y

  igSetNextWindowPos(ImVec2(x: 0, y: menuBarHeight), 0, ImVec2(x: 0, y: 0))
  igSetNextWindowSize(windowSize, 0)
  igBegin("Main Window", nil, (ImGui_WindowFlags_NoTitleBar.uint32 or ImGui_WindowFlags_NoMove.uint32 or ImGui_WindowFlags_NoResize.uint32).ImGuiWindowFlags)
  globalWindowPadding = igGetStyle().WindowPadding
  
  #if(app.popupInfo.needOpen):
  #  app.popupInfo.needOpen = false
  #  igOpenPopup_Str(app.popupInfo.name, 0)
#
  #let module = app.synth.moduleList[1]
  #if(module != nil and module.popupOpened):
  #  module.drawPopup(app.synth.synthInfos, app.events)

  # let module = if(app.popupInfo.moduleIndex >= 0): app.synth.moduleList[app.popupInfo.moduleIndex] else: nil
  # if (module != nil and module.popupOpened):
  #   module.drawPopup(app.popupInfo.moduleIndex, app.synth.synthInfos, app.events)
  #   if(not module.popupOpened): app.popupInfo.moduleIndex = -1
  
  app.drawSynth(windowSize)

  igSameLine(0, 0)

  
  if(igBeginChild_Str("waveModulesPanels", ImVec2(x: 0, y: windowSize.y - menuBarHeight), ImGui_ChildFlags_AlwaysUseWindowPadding.cint, 0)):
    app.drawWavePreview()
    drawModulesList()
        
    igEndChild()

  igEnd()