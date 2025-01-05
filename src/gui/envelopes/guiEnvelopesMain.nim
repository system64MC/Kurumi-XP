import imguin/[glfw_opengl,cimgui]
import strformat
import ../../utils
import ../../events
import ../../maths
import ../../globals
import ../../synthesizer/modules/moduleSynthGeneric
import ../../synthesizer/synthInfos
import ../widgets

const modeStrings = ["None".cstring, "ADSR", "Waveform"]

proc addQuadFilledMultiColor(dl: ptr struct_ImDrawList, p1, p2, p3, p4: ImVec2, col1: ImU32, col2: ImU32, col3: ImU32, col4: ImU32) =
  let uv = dl.internal_Data.TexUvWhitePixel
  dl.ImDrawList_PrimReserve(6, 4)

  dl.ImDrawList_PrimWriteIdx(dl.internal_VtxCurrentIdx.ImDrawIdx)
  dl.ImDrawList_PrimWriteIdx((dl.internal_VtxCurrentIdx + 1).ImDrawIdx)
  dl.ImDrawList_PrimWriteIdx((dl.internal_VtxCurrentIdx + 2).ImDrawIdx)

  dl.ImDrawList_PrimWriteIdx(dl.internal_VtxCurrentIdx.ImDrawIdx)
  dl.ImDrawList_PrimWriteIdx((dl.internal_VtxCurrentIdx + 2).ImDrawIdx)
  dl.ImDrawList_PrimWriteIdx((dl.internal_VtxCurrentIdx + 3).ImDrawIdx)

  dl.ImDrawList_PrimWriteVtx(p1, uv, col1)
  dl.ImDrawList_PrimWriteVtx(p2, uv, col2)
  dl.ImDrawList_PrimWriteVtx(p3, uv, col3)
  dl.ImDrawList_PrimWriteVtx(p4, uv, col4)

proc drawAdsr(envelope: var Adsr, min, max: float, eventList: var EventList, moduleName: string, envName: string, macroLen: int, strictClip: bool) =
  igBeginChild_Str("##AdsrControls", ImVec2(x: 0, y: 0), ord ord (ImGui_ChildFlags_AlwaysAutoResize.int32 or ImGui_ChildFlags_AutoResizeX.int32 or ImGuiChildFlags_AutoResizeY.int32), 0)
  
  knobFloat[float32]("Start", envelope.start.addr, min, max, 0, size = 64, clip_min = min, clip_max = max, clip = strictClip)
  .treatAction(eventList, fmt"{moduleName} {envName} envelope: Start set to {envelope.start}")
  igSameLine(0, 2)
  knobInteger[int32]("Delay", envelope.delay.addr, 0, 256, 0, size = 64)
  .treatAction(eventList, fmt"{moduleName} {envName} envelope: Delay set to {envelope.delay}")
  igSameLine(0, 2)
  knobInteger[int32]("Attack", envelope.attack.addr, 0, 256, 0, size = 64)
  .treatAction(eventList, fmt"{moduleName} {envName} envelope: Attack set to {envelope.attack}")
  igSameLine(0, 2)
  knobInteger[int32]("Hold", envelope.hold.addr, 0, 256, 0, size = 64)
  .treatAction(eventList, fmt"{moduleName} {envName} envelope: Hold set to {envelope.hold}")
  igSameLine(0, 2)
  knobFloat[float32]("Peak", envelope.peak.addr, min, max, 0, size = 64, clip_min = min, clip_max = max, clip = strictClip)
  .treatAction(eventList, fmt"{moduleName} {envName} envelope: Peak set to {envelope.peak}")
  igSameLine(0, 2)
  knobInteger[int32]("Decay", envelope.decay.addr, 0, 256, 0, size = 64)
  .treatAction(eventList, fmt"{moduleName} {envName} envelope: Decay set to {envelope.decay}")
  
  knobFloat[float32]("Sustain", envelope.sustain.addr, min, max, 0, size = 64, clip_min = min, clip_max = max, clip = strictClip)
  .treatAction(eventList, fmt"{moduleName} {envName} envelope: Sustain set to {envelope.sustain}")
  igSameLine(0, 2)
  knobInteger[int32]("Atck 2", envelope.attack2.addr, 0, 256, 0, size = 64)
  .treatAction(eventList, fmt"{moduleName} {envName} envelope: Attack 2 set to {envelope.attack2}")
  igSameLine(0, 2)
  knobFloat[float32]("Peak 2", envelope.peak2.addr, min, max, 0, size = 64, clip_min = min, clip_max = max, clip = strictClip)
  .treatAction(eventList, fmt"{moduleName} {envName} envelope: Peak 2 set to {envelope.peak2}")
  igSameLine(0, 2)
  knobInteger[int32]("Dec 2", envelope.decay2.addr, 0, 256, 0, size = 64)
  .treatAction(eventList, fmt"{moduleName} {envName} envelope: Decay 2 set to {envelope.decay2}")
  igSameLine(0, 2)
  knobFloat[float32]("Sus 2", envelope.sustain2.addr, min, max, 0, size = 64, clip_min = min, clip_max = max, clip = strictClip)
  .treatAction(eventList, fmt"{moduleName} {envName} envelope: Sustain 2 set to {envelope.sustain2}")
  igEndChild()
  var rectSize: ImVec2
  var availlableRegion: ImVec2
  igGetItemRectSize(rectSize.addr)
  igSameLine(0, 2)
  igGetContentRegionAvail(availlableRegion.addr)
  igBeginChild_Str("##envGraph", ImVec2(x: availlableRegion.x, y: rectSize.y), ord ord (ImGui_ChildFlags_AlwaysAutoResize.int32 or ImGui_ChildFlags_AutoResizeX.int32), 0)
  
  igGetContentRegionAvail(availlableRegion.addr)
  var pos: ImVec2
  igGetCursorScreenPos(pos.addr)

  let dl = igGetWindowDrawList()
  dl.ImDrawList_AddRectFilled(
    pos,
    pos + availlableRegion, igGetStyle().Colors[ImGui_Col_FrameBg.cint].igColorConvertFloat4ToU32(), 0.0, 0)

  if(macroLen == 0): return
  #time pos
  var posX = 0.0
  var sizeX = availlableRegion.x

  let start = envelope.start / max * (availlableRegion.y - 1)
  let delay = (envelope.delay.float32 / 256.0) # Adjust this factor to control the timing
  let attack = (envelope.attack.float32 / 256.0) # Adjust this factor to control the timing
  let peak1 = envelope.peak / max * (availlableRegion.y - 1)
  let hold = (envelope.hold.float32 / 256.0)
  let decay = (envelope.decay.float32 / 256.0)
  let sustain = envelope.sustain / max * (availlableRegion.y - 1)
  let attack2 = (envelope.attack2.float32 / 256.0) # Adjust this factor to control the timing
  let peak2 = envelope.peak2 / max * (availlableRegion.y - 1)
  let decay2 = (envelope.decay2.float32 / 256.0)
  let sustain2 = envelope.sustain2 / max * (availlableRegion.y - 1)

  let ratio = 256.0 / (macroLen.float - 1)

  let p1 = ImVec2(x: pos.x + posX, y: pos.y + (availlableRegion.y - 1) - start)
  posX +=  sizeX * delay
  let p2 = ImVec2(x: pos.x + posX, y: pos.y + (availlableRegion.y - 1) - start)
  posX += ratio * sizeX * attack
  let p3 = ImVec2(x: pos.x + posX + attack, y: pos.y + (availlableRegion.y - 1) - peak1)
  posX += ratio * sizeX * hold
  let p4 = ImVec2(x: pos.x + posX + attack, y: pos.y + (availlableRegion.y - 1) - peak1)
  posX += ratio * sizeX * decay
  let p5 = ImVec2(x: pos.x + posX + decay, y: pos.y + (availlableRegion.y - 1) - sustain)
  posX += ratio * sizeX * attack2
  let p6 = ImVec2(x: pos.x + posX + attack2, y: pos.y + (availlableRegion.y - 1) - peak2)
  posX += ratio * sizeX * decay2
  let p7 = ImVec2(x: pos.x + posX + decay2, y: pos.y + (availlableRegion.y - 1) - sustain2)
  posX += availlableRegion.x - posX
  let p8 = ImVec2(x: pos.x + posX, y: p7.y)

  let col1 = globalColorsScheme[GlobalCol_WavePrev1].igColorConvertFloat4ToU32()
  let col2 = globalColorsScheme[GlobalCol_WavePrev2].igColorConvertFloat4ToU32()

  dl.addQuadFilledMultiColor(
    p1, p2,
    ImVec2(x: p2.x, y: p2.y + availlableRegion.y - (p2.y - pos.y)),
    ImVec2(x: p1.x, y: p1.y + availlableRegion.y - (p1.y - pos.y)),
    colorLerp(col1, col2, 1 - (clamp(envelope.start, min, max) / max)),
    colorLerp(col1, col2, 1 - (clamp(envelope.start, min, max) / max)),
    col2, col2
  )

  dl.addQuadFilledMultiColor(
    p2, p3,
    ImVec2(x: p3.x, y: p3.y + availlableRegion.y - (p3.y - pos.y)),
    ImVec2(x: p2.x, y: p2.y + availlableRegion.y - (p2.y - pos.y)),
    colorLerp(col1, col2, 1 - (clamp(envelope.start, min, max) / max)), colorLerp(col1, col2, 1 - (clamp(envelope.peak, min, max) / max)),
    col2, col2
  )

  dl.addQuadFilledMultiColor(
    p3, p4,
    ImVec2(x: p4.x, y: p4.y + availlableRegion.y - (p4.y - pos.y)),
    ImVec2(x: p3.x, y: p3.y + availlableRegion.y - (p3.y - pos.y)),
    colorLerp(col1, col2, 1 - (clamp(envelope.peak, min, max) / max)), colorLerp(col1, col2, 1 - (clamp(envelope.peak, min, max) / max)),
    col2, col2
  )

  dl.addQuadFilledMultiColor(
    p4, p5,
    ImVec2(x: p5.x, y: p5.y + availlableRegion.y - (p5.y - pos.y)),
    ImVec2(x: p4.x, y: p4.y + availlableRegion.y - (p4.y - pos.y)),
    colorLerp(col1, col2, 1 - (clamp(envelope.peak, min, max) / max)), colorLerp(col1, col2, 1 - (clamp(envelope.sustain, min, max) / max)),
    col2, col2
  )

  dl.addQuadFilledMultiColor(
    p5, p6,
    ImVec2(x: p6.x, y: p6.y + availlableRegion.y - (p6.y - pos.y)),
    ImVec2(x: p5.x, y: p5.y + availlableRegion.y - (p5.y - pos.y)),
    colorLerp(col1, col2, 1 - (clamp(envelope.sustain, min, max) / max)), colorLerp(col1, col2, 1 - (clamp(envelope.peak2, min, max) / max)),
    col2, col2
  )

  dl.addQuadFilledMultiColor(
    p6, p7,
    ImVec2(x: p7.x, y: p7.y + availlableRegion.y - (p7.y - pos.y)),
    ImVec2(x: p6.x, y: p6.y + availlableRegion.y - (p6.y - pos.y)),
    colorLerp(col1, col2, 1 - (clamp(envelope.peak2, min, max) / max)), colorLerp(col1, col2, 1 - (clamp(envelope.sustain2, min, max) / max)),
    col2, col2
  )

  dl.addQuadFilledMultiColor(
    p7, p8,
    ImVec2(x: p8.x, y: p8.y + availlableRegion.y - (p8.y - pos.y)),
    ImVec2(x: p7.x, y: p7.y + availlableRegion.y - (p7.y - pos.y)),
    colorLerp(col1, col2, 1 - (clamp(envelope.sustain2, min, max) / max)), colorLerp(col1, col2, 1 - (clamp(envelope.sustain2, min, max) / max)),
    col2, col2
  )

  dl.ImDrawList_AddLine(p1, p2, globalColorsScheme[GlobalCol_WavePrevLine].igColorConvertFloat4ToU32(), 2.0)
  dl.ImDrawList_AddLine(p2, p3, globalColorsScheme[GlobalCol_WavePrevLine].igColorConvertFloat4ToU32(), 2.0)
  dl.ImDrawList_AddLine(p3, p4, globalColorsScheme[GlobalCol_WavePrevLine].igColorConvertFloat4ToU32(), 2.0)
  dl.ImDrawList_AddLine(p4, p5, globalColorsScheme[GlobalCol_WavePrevLine].igColorConvertFloat4ToU32(), 2.0)
  dl.ImDrawList_AddLine(p5, p6, globalColorsScheme[GlobalCol_WavePrevLine].igColorConvertFloat4ToU32(), 2.0)
  dl.ImDrawList_AddLine(p6, p7, globalColorsScheme[GlobalCol_WavePrevLine].igColorConvertFloat4ToU32(), 2.0)
  dl.ImDrawList_AddLine(p6, p7, globalColorsScheme[GlobalCol_WavePrevLine].igColorConvertFloat4ToU32(), 2.0)
  dl.ImDrawList_AddLine(p7, p8, globalColorsScheme[GlobalCol_WavePrevLine].igColorConvertFloat4ToU32(), 2.0)

  igEndChild()
  return

proc draw*(envelope: var Adsr, module: ModuleSynthGeneric, infos: var SynthInfos, min, max: float, eventList: var EventList, moduleName: string, envName: string, strictClip: bool = false) =
  var availlableRegion: ImVec2
  igGetContentRegionAvail(availlableRegion.addr)
  igBeginChild_Str("##envs", ImVec2(x: availlableRegion.x, y: 0), ord (ImGui_ChildFlags_Borders.int32 or ImGui_ChildFlags_AlwaysAutoResize.int32 or ImGui_ChildFlags_AutoResizeX.int32 or ImGuiChildFlags_AutoResizeY.int32), 0)
  discard miniOsc("ABCD", module.waveDisplay.addr)
  igSetNextItemWidth(128)
  sliderScalar[int32]("##macLen", IgDataType.S32, infos.macroLen.addr, 1, 256, fmt"Seq. Length: {infos.macroLen}", IgSliderFlags.None)
  .treatAction(eventList, fmt"Sequence Length set to {infos.macroLen}")
  igSetNextItemWidth(128)
  sliderScalar[int32]("##macFrame", IgDataType.S32, infos.macroFrame.addr, 0, infos.macroLen - 1, fmt"Frame: {infos.macroFrame}", IgSliderFlags.AlwaysClamp)
  .treatAction(eventList, fmt"Sequence Frame set to {infos.macroFrame}")
  igSetNextItemWidth(128)
  sliderScalar[uint8]("##envMode", IgDataType.U8, envelope.mode.addr, 0, modeStrings.len - 1, fmt"Mode: {modeStrings[envelope.mode]}", IgSliderFlags.AlwaysClamp)
  .treatAction(eventList, fmt"{moduleName} {envName} envelope: Mode set to {modeStrings[envelope.mode]}")
  
  case envelope.mode
  of 0: discard
  of 1: envelope.drawAdsr(min, max,eventList, moduleName, envName, infos.macroLen, strictClip)
  else: discard
  
  igEndChild()