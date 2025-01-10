import std/[strutils, math]
import nimgl/[opengl,glfw]

import imguin/[glfw_opengl,cimgui]

import flatty

import ../../synthesizer/synth
import ../../synthesizer/synthInfos
import ../../synthesizer/modules/moduleSynthGeneric
import ../../synthesizer/modules/moduleSynthOutput
import ../../synthesizer/modules/modulesSummoning
import ../../synthesizer/modules/modulesEnum
import ../../globals
import ../../app
import ../../events
import ../../utils
import ../../maths
import ../../fonts/IconsFontAwesome6
import ../../systemFonts
import strformat

proc drawLinks*(app: KuruApp) =
  for m in 0.int32..<MAX_MODULES:
    let module = app.synth.moduleList[m]
    if(module == nil): continue
    if(module.outputs.len == 0): continue
    
    for destPin in module.outputs:
      if(destPin.moduleIndex < 0): continue
      let destModule = app.synth.moduleList[destPin.moduleIndex]
      if(destModule == nil): continue
      if(destModule.inputs.len == 0): continue
      let sourcePin = destModule.inputs[destPin.pinIndex]
      if(sourcePin.moduleIndex < 0): continue
      let linkId = createLink(sourcePin, destPin).toInt32
      imnodes_Link(
        linkId, 
        sourcePin.createSmallPinConnection(true).toInt32, 
        destPin.createSmallPinConnection(false).toInt32)

proc detectLinksModifications*(app: KuruApp) =
  var linkStart, linkEnd: int32 = -1
  if(imnodes_IsLinkCreated_BoolPtr(linkStart.addr, linkEnd.addr, nil)):
    # app.events.push(Event.new(EVENT_LINK_CREATED, toFlatty((outputPin: Link(linkStart).unsetOutput(), inputPin: Link(linkEnd)))))
    app.events.push(Event.new(EVENT_LINK_CREATED, toFlatty(
      ModuleLink(
        source: linkStart.toSmallPinConnection(),
        dest: linkEnd.toSmallPinConnection(),
      )
    )))
  var linkId: int32 = 0
  if(imnodes_IsLinkDestroyed(linkId.addr)):
    app.events.push(Event.new(EVENT_LINK_DESTROYED, toFlatty(linkId.toModuleLink())))

proc manageModuleDrop*(app: KuruApp, mousePos: ImVec2) =
  if(igBeginDragDropTarget()):
    let data = igAcceptDragDropPayload("modulesList", ImGuiDragDropFlags_AcceptBeforeDelivery.cint)
    if(not igIsMouseDragging(ImGuiMouseButton_Left.cint, 0)):
      if(data != nil):
        # TODO : Display a warning if module list is full.
        # discard 
        app.events.push(
          Event.new(EVENT_ADD_MODULE, toFlatty((module: cast[ptr ModuleType](data.Data)[], position: Vec2[float32](x: mousePos.x, y: mousePos.y))))
        )
    
    igEndDragDropTarget()

proc drawTitleBar(module: ModuleSynthGeneric, m: int32, events: var EventList) =
  imnodes_BeginNodeTitleBar()
  withFont(module.title.bank):
    igText(module.title.data.cstring)
  igSameLine(0, 0)
  var spaceVec = ImVec2(x: 0, y: 0)
  imnodes_GetNodeDimensions(spaceVec.addr, m.cint)
  let posX = igGetCursorPosX()
  var nodePos = ImVec2(x: 0, y: 0)
  imnodes_GetNodeEditorSpacePos(nodePos.addr, m.cint)
  igSetCursorPosX(nodePos.x + spaceVec.x - (if(module of ModuleSynthOutput): 28 else: 50))
  if(igButton(if(module.isMaxed): fmt"{ICON_FA_CHEVRON_UP}" else: fmt"{ICON_FA_CHEVRON_DOWN}", ImVec2(x: 20, y: 20))):
    module.isMaxed = not module.isMaxed
  if not(module of ModuleSynthOutput):
    igSameLine(0, 2)
    if(igButton(fmt"{ICON_FA_XMARK}", ImVec2(x: 20, y: 20))):
      events.push(Event.new(EVENT_MODULE_DELETED, toFlatty((moduleIndex: m.int16, moduleTitle: module.title))))
  imnodes_EndNodeTitleBar()

proc drawInputs*(module: ModuleSynthGeneric, m: int32) =
  for i in 0.int32..<module.inputs.len:
    imnodes_BeginInputAttribute(createSmallPinConnection(m.uint8, i.uint8, false).toInt32, ImNodesPinShape_Triangle.cint)
    if(module.isMaxed): igText("\n")
    imnodes_EndInputAttribute()

proc drawOutputs*(module: ModuleSynthGeneric, m: int32) =
  for i in 0..<module.outputs.len:
    imnodes_BeginOutputAttribute(createSmallPinConnection(m.uint8, i.uint8, true).toInt32, ImNodesPinShape_Triangle.cint)
    if(module.isMaxed): igText("\n")
    imnodes_EndOutputAttribute()

proc getMousePosInEditor(): ImVec2 =
    # Getting the mouse position relative to the editor
  var absMousePos = ImVec2()
  var camPos = ImVec2(x: 0, y: 0)
  var windowPos = ImVec2(x: 0, y: 0)
  imnodes_EditorContextGetPanning(camPos.addr)
  imnodes_PushAttributeFlag(ImNodesAttributeFlags_EnableLinkDetachWithDragClick.cint or ImNodesAttributeFlags_EnableLinkCreationOnSnap.cint)
  igGetWindowPos(windowPos.addr)
  igGetMousePos(absMousePos.addr)
  absMousePos.x -= windowPos.x + camPos.x
  absMousePos.y -= windowPos.y + camPos.y
  return absMousePos

proc drawModule*(module: ModuleSynthGeneric, m: int32, hoveredNode: int32, infos: var SynthInfos, events: var EventList): EventModuleGui =
  result = EventModuleGui.GUI_NONE
  let isNodeHovered = m == hoveredNode
  let isNodeSelected = imnodes_IsNodeSelected(m.cint)
  if(isNodeSelected):
    imnodes_PushColorStyle(ord ImNodesCol_NodeOutline, globalColorsScheme[GlobalCol_SelectedNodeOutline].igColorConvertFloat4ToU32())
  elif(isNodeHovered):
    imnodes_PushColorStyle(ord ImNodesCol_NodeOutline, globalColorsScheme[GlobalCol_HoveredNodeOutline].igColorConvertFloat4ToU32())
  defer:
    if(isNodeSelected or isNodeHovered):
      imnodes_PopColorStyle()

  imnodes_BeginNode(m.cint)

  module.drawTitleBar(m, events)

  if(isNodeSelected):
    var v = ImVec2()
    imnodes_GetNodeGridSpacePos(v.addr, m)
    module.position.x = v.x
    module.position.y = v.y
  else:
    imnodes_SetNodeGridSpacePos(m, ImVec2(x: module.position.x, y: module.position.y))

  igBeginTable("table", 3, 0.cint, ImVec2(x: 11 + module.contentWidth + 11, y: 0), 0)
  igTableSetupColumn("inputs", ImGuiTableColumnFlags_WidthFixed.cint, 0.0, 0)
  igTableSetupColumn("stuff", ImGui_TableColumnFlags_WidthStretch.cint, module.contentWidth, 0)
  igTableSetupColumn("outputs", ImGuiTableColumnFlags_WidthFixed.cint, 0.0, 0)
  igTableNextRow(0, 0)
  igTableSetColumnIndex(0)

  module.drawInputs(m)

  igTableSetColumnIndex(1)

  if(module.isMaxed):
    igBeginDisabled(not isNodeSelected)
    result = module.draw(infos, isNodeSelected, events)
      #app.modulePopupOpened = module
      #openPopup = true
    igEndDisabled()

  igTableSetColumnIndex(2)

  module.drawOutputs(m)

  igEndTable()
  imnodes_EndNode()

proc drawSynth*(app: KuruApp, windowSize: ImVec2) =
  var absMousePos = ImVec2()
  var availlableReg: ImVec2
  igGetContentRegionAvail(availlableReg.addr)
  var openPopup = false


  if(igBeginChild_Str("synthView", ImVec2(x: availlableReg.x - WAVE_PREVIEW_PANEL_SIZE, y: windowSize.y - menuBarHeight), 0, 0)):
    
    let style = imnodes_GetStyle()
    var hoveredNode: int32 = -1
    discard imnodes_IsNodeHovered(hoveredNode.addr)
    style.NodeCornerRounding = 11
    imnodes_BeginNodeEditor()

    if(igIsKeyDown_ID(ImGuiKey_LeftShift, 0)):
      imnodes_GetStyle().Flags = imnodes_GetStyle().Flags or ImNodesStyleFlags_GridSnapping.cint
    else:
      imnodes_GetStyle().Flags = imnodes_GetStyle().Flags and (not ImNodesStyleFlags_GridSnapping.cint)

    let absMousePos = getMousePosInEditor()

    let synth = app.synth
    
    for m in 0.int32..<MAX_MODULES:
      let module = synth.moduleList[m]
      if(module == nil): continue
      let guiEvent = drawModule(module, m, hoveredNode, synth.synthInfos, app.events)
      if(guiEvent == EventModuleGui.GUI_OPEN_POPUP):
        app.modulePopupOpened = module
        openPopup = true


    app.drawLinks()
      
    imnodes_MiniMap(0.1, ImNodesMiniMapLocation_TopLeft.cint, nil, nil)
    imnodes_PopAttributeFlag()
    imnodes_EndNodeEditor()
    app.detectLinksModifications()
    app.manageModuleDrop(absMousePos)
    
    if(app.modulePopupOpened != nil):
      if(openPopup):
        igOpenPopup_Str(app.modulePopupOpened.popupTitle, 0)
      app.modulePopupOpened.drawPopup(app.synth.synthInfos, app.events)
      if(not app.modulePopupOpened.popupOpened):
        app.modulePopupOpened = nil
    igEndChild()
