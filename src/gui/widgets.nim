import imguin/[glfw_opengl,cimgui]

import ../events
import ../globals

import ../systemFonts
import ../fonts/IconsFontAwesome6
import ../fonts/IconsFontAudio
import strformat

type
  WidgetAction* = enum
    WIDGET_NONE
    WIDGET_MODIFIED
    WIDGET_RELEASED

proc knobInteger*[T: SomeInteger](
    label: cstring; 
    p_value: ptr T; 
    v_min: T; 
    v_max: T;
    steps: cint;
    speed: cfloat = 0; 
    format: cstring = "%i"; 
    variant: IgKnobVariant = IgKnobVariant_Tick;
    size: cfloat = 0; 
    flags: IgKnobFlags = cast[IgKnobFlags](0.cuint); 
    angle_min: cfloat = -1; 
    angle_max: cfloat = -1;
    clip_min: T = 0;
    clip_max: T = 0;
    clip = false
): WidgetAction = 
  var tmp = (p_value[]).cint
  var a = igGetStyleColorVec4(ImGuiCol_FrameBgActive.ImGuiCol)[]
  var b = igGetStyleColorVec4(ImGuiCol_FrameBgHovered.ImGuiCol)[]
  var c = igGetStyleColorVec4(ImGuiCol_FrameBg.ImGuiCol)[]
  b.x *= 2
  b.y *= 2
  b.z *= 2
  b.w *= 2

  c.x *= 2
  c.y *= 2
  c.z *= 2
  c.w *= 2
  
  igPushStyleColor_Vec4(ImGuiCol_ButtonHovered.ImGuiCol, b)
  igPushStyleColor_Vec4(ImGuiCol_ButtonActive.ImGuiCol,  c)
  let res = IgKnobInt(label, tmp.addr, v_min.cint, v_max.cint, speed, format, variant, size, flags, steps, angle_min, angle_max)
  igPopStyleColor(2)
  p_value[] = T(tmp)  # Convert back to the generic type
  if(clip): p_value[] = clamp(p_value[], clip_min, clip_max)
  if igIsItemDeactivated(): return WIDGET_RELEASED
  if res: return WIDGET_MODIFIED
  return WIDGET_NONE


proc knobFloat*[T: SomeFloat](
    label: cstring; 
    p_value: ptr T; 
    v_min: T; 
    v_max: T;
    steps: cint;
    speed: cfloat = 0; 
    format: cstring = "%.4f"; 
    variant: IgKnobVariant = IgKnobVariant_Tick;
    size: cfloat = 0; 
    flags: IgKnobFlags = cast[IgKnobFlags](0.cuint); 
    angle_min: cfloat = -1; 
    angle_max: cfloat = -1;
    clip_min: T = 0;
    clip_max: T = 0;
    clip = false
): WidgetAction =
  var tmp = (p_value[]).cfloat
  var a = igGetStyleColorVec4(ImGuiCol_FrameBgActive.ImGuiCol)[]
  var b = igGetStyleColorVec4(ImGuiCol_FrameBgHovered.ImGuiCol)[]
  var c = igGetStyleColorVec4(ImGuiCol_FrameBg.ImGuiCol)[]
  b.x *= 2
  b.y *= 2
  b.z *= 2
  b.w *= 2

  c.x *= 2
  c.y *= 2
  c.z *= 2
  c.w *= 2
  
  igPushStyleColor_Vec4(ImGuiCol_ButtonHovered.ImGuiCol, b)
  igPushStyleColor_Vec4(ImGuiCol_ButtonActive.ImGuiCol,  c)
  let res = IgKnobFloat(label, tmp.addr, v_min.float32, v_max.float32, speed, format, variant, size, flags, steps, angle_min, angle_max)
  igPopStyleColor(2)
  p_value[] = T(tmp)  # Convert back to the generic type
  if(clip): p_value[] = clamp(p_value[], clip_min, clip_max)
  if igIsItemDeactivated(): return WIDGET_RELEASED
  if res: return WIDGET_MODIFIED
  return WIDGET_NONE

type
  IgDataType* {.size: sizeof(cuint).} = enum
    S8 = 0, U8 = 1, S16 = 2,
    U16 = 3, S32 = 4, U32 = 5,
    S64 = 6, U64 = 7, F32 = 8,
    F64 = 9, BOOL = 10, COUNT = 11

  IgSliderFlags* {.size: sizeof(cuint).} = enum
    None = 0, Logarithmic = 32,
    NoRoundToFormat = 64, NoInput = 128,
    WrapAround = 256, ClampOnInput = 512,
    ClampZeroRange = 1024, AlwaysClamp = 1536,
    InvalidMask_private = 1879048207

proc sliderScalar*[T: SomeNumber](
    label: cstring;
    dataType: IgDataType;
    p_data: ptr T; 
    v_min: T; 
    v_max: T;
    format: cstring; 
    flags: IgSliderFlags;
    isVertical = false;
    size: ImVec2 = ImVec2(x: 0, y: 0);
    clip_min: T = 0;
    clip_max: T = 0;
    clip = false
): WidgetAction =
  let res = if(isVertical): igVSliderScalar(label, size, dataType.ImGuiDataType, p_data, v_min.addr, v_max.addr, format, flags.ImGuiSliderFlags)
  else: igSliderScalar(label, dataType.ImGuiDataType, p_data, v_min.addr, v_max.addr, format, flags.ImGuiSliderFlags)
  if(clip):
    p_data[] = clamp(p_data[], clip_min, clip_max)
  if igIsItemDeactivatedAfterEdit(): return WIDGET_RELEASED
  if res: return WIDGET_MODIFIED
  return WIDGET_NONE

proc sliderFloat32*(
    label: cstring;
    p_data: ptr cfloat; 
    v_min: cfloat; 
    v_max: cfloat;
    format: cstring; 
    flags: IgSliderFlags;
    isVertical = false;
    size: ImVec2 = ImVec2(x: 0, y: 0)
): WidgetAction =
  let res = if(isVertical): igVSliderFloat(label, size, p_data, v_min, v_max, format, flags.ImGuiSliderFlags)
  else: igSliderFloat(label, p_data, v_min, v_max, format, flags.ImGuiSliderFlags)
  if igIsItemDeactivatedAfterEdit(): return WIDGET_RELEASED
  if res: return WIDGET_MODIFIED
  return WIDGET_NONE

import math
import ../globals
const MINI_OSC_INNER_W = 128
const MINI_OSC_INNER_H = 48

const COLORS_NORMAL = [
  0x00A77B00.uint32,
  0x00A77B00.uint32,
  0xDF78C850.uint32,
  0xDF78C850.uint32
]


# 0xFF0045FF.uint32,
# 0xFFFF901E.uint32


const COLORS_SATURATED = [
  0x00A77B00.uint32,
  0x00A77B00.uint32,
  0xDF8737af.uint32,
  0xDF8737af.uint32,
];
proc miniOsc*(
    label: cstring;
    data: ptr array[MODULE_DISPLAY_RESOLUTION, float32];
): bool =
  assert data != nil
  #igPushID_Str(label)
  #igPushItemWidth(width)
  const width = MINI_OSC_INNER_W
  const height = MINI_OSC_INNER_H
  igBeginGroup()
  igPushStyleVarX(ImGui_StyleVar_FramePadding.cint, 0.0)
  igBeginTable(label, 1, ImGui_TableFlags_Borders.cint, ImVec2(x: width + 2, y: height + 4), 0)
  var pos: ImVec2
  igGetCursorScreenPos(pos.addr)
  let posIni = pos
  pos.y += (height / 2) + 1.5
  let dl = igGetWindowDrawList()
  let color = igColorConvertFloat4ToU32(igGetStyle().Colors[ImGui_Col_FrameBg.cint])
  dl.ImDrawList_AddRectFilled(
    ImVec2(x: posIni.x, y: posIni.y),
    ImVec2(x: posIni.x + width + 2, y: posIni.y + height + 4),
    color, 0.0, 0
  )
  let col1 = globalColorsScheme[GlobalCol_WavePrev1].igColorConvertFloat4ToU32()
  let col2 = globalColorsScheme[GlobalCol_WavePrev2].igColorConvertFloat4ToU32()
  let colLine = globalColorsScheme[GlobalCol_WavePrevLine].igColorConvertFloat4ToU32()
  for i in 0..<data[].len:
    var sample = -data[][i.int]
    var sample1 = -data[][(i.int + 1) mod MODULE_DISPLAY_RESOLUTION]
    let sampleClipped = clamp(sample, -1.0, 1.0)
    let sample1Clipped = clamp(sample1, -1.0, 1.0)
    let sampleSaturated = sample > 1.0 or sample < -1.0
    let sample1Saturated = sample1 > 1.0 or sample1 < -1.0
    # dl.ImDrawList_AddRectFilledMultiColor(
    #   ImVec2(x: pos.x + 1 + i.float, y: pos.y),
    #   ImVec2(
    #     x: pos.x + 1 + i.float + 1, 
    #     y: pos.y + (height / 2) * sampleClipped),
    #     if(sampleSaturated): COLORS_SATURATED[0] else: 0x00A77B00.uint32, 
    #     if(sampleSaturated): COLORS_SATURATED[1] else: 0x00A77B00.uint32, 
    #     if(sampleSaturated): COLORS_SATURATED[2] else: 0xDF78C850.uint32, 
    #     if(sampleSaturated): COLORS_SATURATED[3] else: 0xDF78C850.uint32
    # )

    dl.ImDrawList_AddRectFilledMultiColor(
      ImVec2(x: pos.x + 1 + i.float, y: pos.y),
      ImVec2(
        x: pos.x + 1 + i.float + 1, 
        y: pos.y + (height / 2) * sampleClipped),
        col2.uint32, 
        col2.uint32, 
        col1.uint32, 
        col1.uint32
    )

    #dl.ImDrawList_AddRectFilled(
    #  ImVec2(
    #    x: pos.x + 1 + i.float + 1, 
    #    y: -1 + pos.y + (height / 2) * sampleClipped),
    #  ImVec2(
    #    x: 1.0 + pos.x + 1 + i.float + 1, 
    #    y: 1.0 + pos.y + (height / 2) * sampleClipped),
    #    if(sample1Saturated): COLORS_SATURATED[2] else: 0xDF78C850.uint32,
    #    0.0, 0
    #)
    # dl.ImDrawList_AddLine(
    #   ImVec2(
    #     x: pos.x + 1 + i.float,
    #     y: pos.y + (height / 2) * sampleClipped
    #   ),
    #   ImVec2(
    #     x: pos.x + 1 + i.float + 1,
    #     y: pos.y + (height / 2) * sample1Clipped
    #   ),
    #   if(sampleSaturated): COLORS_SATURATED[3] else: 0xDF78C850.uint32, 2.0
    # )
    dl.ImDrawList_AddLine(
      ImVec2(
        x: pos.x + 1 + i.float,
        y: pos.y + (height / 2) * sampleClipped
      ),
      ImVec2(
        x: pos.x + 1 + i.float + 1,
        y: pos.y + (height / 2) * sample1Clipped
      ),
      colLine, 2.0
    )
  # igGetWindowDrawList().ImDrawList_AddCircle(pos, 10.0, 0xFF_FF_FF_00.uint32, 32, 2)
  defer:
    igEndTable()
    igPopStyleVar(1)
    igEndGroup()
    #igPopID()
  return false

proc treatAction*(action: WidgetAction, eventList: var EventList, arg: string) =
  case action:
    of WIDGET_RELEASED:
      eventList.push(Event.new(EVENT_MODIFIED, arg))
    of WIDGET_MODIFIED:
      eventList.push(Event.new(EVENT_NEED_UPDATE, arg))
    of WIDGET_NONE:
      discard

proc advancedSettingsButton*(): bool =
  var availlableSpace: ImVec2
  var textSize: ImVec2
  igGetContentRegionAvail(availlableSpace.addr)
  igPushFont(FONT_AWESOME.getFont())
  defer: igPopFont()
  igCalcTextSize(textSize.addr, fmt"{ICON_FA_SLIDERS} Advanced", nil, true, 0.0)
  igSetCursorPosX(igGetCursorPosX() + (availlableSpace.x - (textSize.x + 20)) / 2)
  return igButton(fmt"{ICON_FA_SLIDERS} Advanced", ImVec2(x: textSize.x + 20, y: 0))

proc centerElementX*(elementWidth: float32) =
  var availlableSpace: ImVec2
  igGetContentRegionAvail(availlableSpace.addr)
  igSetCursorPos(ImVec2(x: igGetCursorPosX() + (availlableSpace.x - elementWidth) / 2, y: igGetCursorPosY()))

template moduleModal*(popupName: string, popupOpened: ptr bool, body: untyped): untyped =
  let io = igGetIO()
  var displaySize = io.DisplaySize
  let center = displaySize * 0.5
  igSetNextWindowPos(center, ord ImGui_Cond_Always, ImVec2(x: 0.5, y: 0.5))
  igSetNextWindowSizeConstraints(ImVec2(x: 640, y: 480), displaySize, nil, nil)
  if(igBeginPopupModal(popupName, popupOpened, ord ImGui_WindowFlags_NoMove)):
    body
    igEndPopup()

proc checkBox*(label: cstring, p_data: ptr bool): WidgetAction =
  let res = igCheckbox(label, p_data)
  if(res):
    return WIDGET_MODIFIED
  else:
    return WIDGET_NONE

proc toolTip*(text: cstring) =
  if(igIsItemHovered(0) and not igIsItemActive()):
    igPushStyleVar_Vec2(ImGui_StyleVar_WindowPadding.cint, ImVec2(x: 4, y: 4))
    igSetTooltip(text)
    igPopStyleVar(1)