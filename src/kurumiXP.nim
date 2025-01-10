import std/[strutils, math]
import nimgl/[opengl,glfw]

import imguin/[glfw_opengl,cimgui]
import gui/mainWindow/guiMainWindow

import flatty

import synthesizer/synth
import synthesizer/modules/modulesEnum
import app as application
import events
import utils
import maths
import synthesizer/modules/modulesSummoning
import globals
import audioPreview

const MainWinWidth = 1024
const MainWinHeight = 800

import options
import asyncdispatch
import nimpresence

#--------------
# Configration
#--------------

#  .--------------------------------------------..---------.-----------------------.------------
#  |         Combination of flags               ||         |     Viewport          |
#  |--------------------------------------------||---------|-----------------------|------------
#  | fViewport | fDocking | TransparentViewport || Docking | Transparent | Outside | Description
#  |:---------:|:--------:|:-------------------:||:-------:|:-----------:|:-------:| -----------
#  |  false    | false    |     false           ||    -    |     -       |   -     |
#  |  false    | true     |     false           ||    v    |     -       |   -     | (Default): Only docking
#  |  true     | -        |     false           ||    v    |     -       |   v     | Docking and outside of viewport
#  |    -      | -        |     true            ||    v    |     v       |   -     | Transparent Viewport and docking
#  `-----------'----------'---------------------'`---------'-------------'---------'-------------
var
 fDocking = false
 fViewport = false
 TransparentViewport = false
 #
block:
  if TransparentViewport:
    fViewport = true
  if fViewport:
    fDocking = true

proc initWindow(): GLFWWindow =
  doAssert glfwInit()
  # defer: glfwTerminate()

  if TransparentViewport:
    glfwWindowHint(GLFWVisible, GLFW_FALSE)

  glfwWindowHint(GLFWContextVersionMajor, 3)
  glfwWindowHint(GLFWContextVersionMinor, 3)
  glfwWindowHint(GLFWOpenglForwardCompat, GLFW_TRUE)
  glfwWindowHint(GLFWOpenglProfile, GLFW_OPENGL_CORE_PROFILE)
  glfwWindowHint(GLFWResizable, GLFW_TRUE)
  #
  glfwWindowHint(GLFWVisible, GLFW_FALSE)
  var glfwWin = glfwCreateWindow(MainWinWidth, MainWinHeight)
  glfwWin.setWindowTitle("Kurumi XP")
  if glfwWin.isNil:
    quit(-1)
  glfwWin.makeContextCurrent()
  glfwSwapInterval(1) # Enable vsync
  doAssert glInit() # OpenGL init
  return glfwWin

proc setupImGUI(win: glfw.GLFWWindow) =
  # Setup ImGui
  let context = igCreateContext(nil)
  imnodes_CreateContext()
  # defer: context.igDestroyContext()
  if fDocking:
    var pio = igGetIO()
    pio.ConfigFlags = pio.ConfigFlags or ImGui_ConfigFlags_DockingEnable.cint
    if fViewport:
      pio.ConfigFlags = pio.ConfigFlags or ImGui_ConfigFlags_ViewportsEnable.cint
      pio.ConfigViewports_NoAutomerge = true

  # GLFW + OpenGL
  const glsl_version = "#version 130" # GL 3.0 + GLSL 130
  doAssert ImGui_ImplGlfw_InitForOpenGL(cast[ptr GLFWwindow](win), true)
  # defer: ImGui_ImplGlfw_Shutdown()
  doAssert ImGui_ImplOpenGL3_Init(glsl_version)
  # defer: ImGui_ImplOpenGL3_Shutdown()

import synthesizer/modules/moduleSynthGeneric
proc draw*(app: KuruApp) =
  let pio = igGetIO()
  glfwPollEvents()

  # start imgui frame
  ImGui_ImplOpenGL3_NewFrame()
  ImGui_ImplGlfw_NewFrame()
  igNewFrame()

  app.drawMainWindow()

  igRender()
  glClearColor(0.1, 0, 0.2, 0)
  glClear(GL_COLOR_BUFFER_BIT)
  ImGui_ImplOpenGL3_RenderDrawData(igGetDrawData())

  if 0 != (pio.ConfigFlags and ImGui_ConfigFlags_ViewportsEnable.cint):
    var backup_current_window = glfwGetCurrentContext()
    igUpdatePlatformWindows()
    igRenderPlatformWindowsDefault(nil, nil)
    backup_current_window.makeContextCurrent()

  app.window.swapBuffers()

import synthesizer/modules/moduleSynthGeneric
import synthesizer/synthInfos
proc redrawWaves(synth: Synth): void =
  for m in synth.moduleList:
    if(m == nil): continue
    m.updateDisplay(synth.moduleList, synth.synthInfos, 128)

proc treatEvents*(app: KuruApp) =
  for e in app.events:
    case e.eventType:
      of EventType.EVENT_MODIFIED: discard
      of EventType.EVENT_NEED_UPDATE:
        app.synth.synthesize()
        app.synth.redrawWaves()
      of EventType.EVENT_MODULE_DELETED:
        let data = fromFlatty(e.data, tuple[moduleIndex: int16, moduleTitle: string])
        let moduleToDelete = app.synth.moduleList[data.moduleIndex]
        for link in moduleToDelete.inputs:
          if(link.moduleIndex < 0 or link.pinIndex < 0): continue
          let inputModule = app.synth.moduleList[link.moduleIndex]
          if(inputModule == nil): continue
          inputModule.outputs[link.pinIndex] = PinConnection(moduleIndex: -1, pinIndex: -1)
        for link in moduleToDelete.outputs:
          if(link.moduleIndex < 0 or link.pinIndex < 0): continue
          let outputModule = app.synth.moduleList[link.moduleIndex]
          if(outputModule == nil): continue
          outputModule.inputs[link.pinIndex] = PinConnection(moduleIndex: -1, pinIndex: -1)
        app.synth.moduleList[data.moduleIndex] = nil
        app.synth.synthesize()
        app.synth.redrawWaves()
      of EventType.EVENT_LINK_CREATED:
        let newLink = fromFlatty(e.data, ModuleLink)
        # Outputing signal
        let outputPinIndex = newLink.source.pinIndex and 0x7F
        let outputModuleIndex = newLink.source.moduleIndex

        # Receiving signal
        let inputPinModule = newLink.dest.pinIndex and 0x7F
        let inputModuleIndex = newLink.dest.moduleIndex

        # The module that outptut the signal
        let outputModule = app.synth.moduleList[outputModuleIndex]
        # The module that receive the signal
        let inputModule = app.synth.moduleList[inputModuleIndex]

        # Here we need to clear the previous link in the receiver
        if(inputModule.inputs[inputPinModule].moduleIndex >= 0 and inputModule.inputs[inputPinModule].pinIndex >= 0):
          # Get the module
          let previousModule = app.synth.moduleList[inputModule.inputs[inputPinModule].moduleIndex]
          if(previousModule != nil):
            previousModule.outputs[inputModule.inputs[inputPinModule].pinIndex] = PinConnection(moduleIndex: -1, pinIndex: -1)
          inputModule.inputs[inputPinModule].moduleIndex = -1
          inputModule.inputs[inputPinModule].pinIndex = -1

        # Here we need to clear the previous link in the sender
        if(outputModule.outputs[outputPinIndex].moduleIndex >= 0 and outputModule.outputs[outputPinIndex].pinIndex >= 0):
          # Get the module
          let previousModule = app.synth.moduleList[outputModule.outputs[outputPinIndex].moduleIndex]
          if(previousModule != nil):
            previousModule.inputs[outputModule.outputs[outputPinIndex].pinIndex] = PinConnection(moduleIndex: -1, pinIndex: -1)
          outputModule.outputs[outputPinIndex].moduleIndex = -1
          outputModule.outputs[outputPinIndex].pinIndex = -1

        assert(outputModule.outputs[outputPinIndex].moduleIndex == -1 and outputModule.outputs[outputPinIndex].pinIndex == -1)
        assert(inputModule.inputs[inputPinModule].moduleIndex == -1 and inputModule.inputs[inputPinModule].pinIndex == -1)
        outputModule.outputs[outputPinIndex] = PinConnection(
          moduleIndex: inputModuleIndex.int16,
          pinIndex: inputPinModule.int16
        )
        # outputModule.outputs[outputPinIndex] = Link(newLink.inputPin.int32)
        
        inputModule.inputs[inputPinModule] = PinConnection(
          moduleIndex: outputModuleIndex.int16,
          pinIndex: outputPinIndex.int16
        )
        app.synth.synthesize()
        app.synth.redrawWaves()
        # inputModule.inputs[inputPinModule] = Link(newLink.outputPin.int32)
        # outputModule.outputs[]
      of EventType.EVENT_ADD_MODULE:
        let data = fromFlatty(e.data, tuple[module: ModuleType, position: Vec2[float32]])
        let moduleIndex = summonToList(data.module, app.synth.moduleList, Vec2[float32](x: data.position.x - 32, y: data.position.y - 16))
        if(moduleIndex >= 0):
          let module = app.synth.moduleList[moduleIndex]
          module.updateDisplay(app.synth.moduleList, app.synth.synthInfos, 128)
      of EventType.EVENT_LINK_DESTROYED:
        let data = fromFlatty(e.data, ModuleLink)
        let sourceModule = app.synth.moduleList[data.source.moduleIndex]
        let destModule = app.synth.moduleList[data.dest.moduleIndex]
        let sourcePinIndex = data.source.pinIndex and 0x7F
        let destPinIndex = data.dest.pinIndex and 0x7F

        sourceModule.outputs[sourcePinIndex] = PinConnection(moduleIndex: -1, pinIndex: -1)
        destModule.inputs[destPinIndex] = PinConnection(moduleIndex: -1, pinIndex: -1)

        app.synth.synthesize()
        app.synth.redrawWaves()

      of EventType.EVENT_OPEN_POPUP:
        let data = fromFlatty(e.data, tuple[moduleIndex: int, popupName: string])
        app.popupInfo.needOpen = true
        app.popupInfo.name = data.popupName
        app.popupInfo.moduleIndex = data.moduleIndex
  app.events.flush()


import systemFonts
import gui/themes
proc init*(t: typedesc[KuruApp]): KuruApp =
  let app = KuruApp()
  app.synth = Synth.create()
  app.synth.synthesize()
  app.window = initWindow()
  app.window.setupImGUI()
  app.window.showWindow()
  igStyleColorsDark(nil)
  imnodes_StyleColorsDark(nil)
  initFonts()
  globalToggleConfig = ImGuiTogglePresets_iOSStyle(0, false)
  setupMoonlightStyle()
  app.synth.addr.initMiniaudio()
  #ImGuiToggleConfig_init(toggleConfig.addr)
  return app

import json
import asyncfutures
import options
import threadpool
import asyncdispatch
import os
proc runRichPresence(app: KuruApp) {.thread.} =
  proc runAsync(app: KuruApp) {.async.} =
    {.cast(gcsafe).}:
      let f = initPresence(clientId = "1322633079143137400")
      asyncfutures.addCallback(f, 
      proc(future: Future[nimpresence.Presence]) = 
        try:
          app.presence = some future.read()
          
        except:
          discard
      )
      while true:
        if(app.presence.isSome()):
          asyncCheck app.presence.get().update(
              state = some "Developping...",
              details = some "test")
          sleep(500)
        else:
          drain(500)
        #await sleepAsync(500)
        # sleep(500)
  waitFor app.runAsync()

const FPS_LIMIT = 1000.0 / 60.0
import times
proc run*(app: KuruApp) {.async.} =
  # spawn app.runRichPresence()

  var timeStart, timeEnd: float
  while app.isOpen():
    timeStart = cpuTime()
    app.treatEvents()
    app.draw()
    timeEnd = cpuTime()
    #sleep(((FPS_LIMIT - timeEnd + timeStart)).int)

when isMainModule:
  let app = KuruApp.init()
  waitFor app.run()
