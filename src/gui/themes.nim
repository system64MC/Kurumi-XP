import std/[strutils, math]
import nimgl/[opengl,glfw]

import imguin/[glfw_opengl,cimgui]
import ../globals
import ../maths

proc setupMoonlightStyle*() = 
  # Moonlight style by Madam-Herta from ImThemes
  let style = igGetStyle()
  let nodeStyle = imnodes_GetStyle()
  
  style.Alpha = 1.0f
  style.DisabledAlpha = 0.300000011920929f
#   style.windowPadding = ImVec2(x: 12.0f, y: 12.0f)
  style.WindowRounding = 11.5f
  style.WindowBorderSize = 0.0f
  style.WindowMinSize = ImVec2(x: 20.0f, y: 20.0f)
  style.WindowTitleAlign = ImVec2(x: 0.5f, y: 0.5f)
  style.WindowMenuButtonPosition = ImGuiDir_Right
  style.ChildRounding = 11.5f
#   style.childBorderSize = 1.0f
  style.PopupRounding = 0.0f
#   style.popupBorderSize = 1.0f
#   style.framePadding = ImVec2(x: 20.0f, y: 3.400000095367432f)
  style.FrameRounding = 11.89999961853027f
  style.FrameBorderSize = 0.0f
  style.ItemSpacing = ImVec2(x: 4.300000190734863f, y: 5.5f)
  style.ItemInnerSpacing = ImVec2(x: 7.099999904632568f, y: 1.799999952316284f)
#   style.cellPadding = ImVec2(x: 12.10000038146973f, y: 9.199999809265137f)
  style.IndentSpacing = 0.0f
  style.ColumnsMinSpacing = 4.900000095367432f
  style.ScrollbarSize = 11.60000038146973f
  style.ScrollbarRounding = 15.89999961853027f
  style.GrabMinSize = 3.700000047683716f
  style.GrabRounding = 20.0f
  style.TabRounding = 0.0f
#   style.tabBorderSize = 0.0f
  style.TabMinWidthForCloseButton = 0.0f
  style.ColorButtonPosition = ImGuiDir.ImGuiDir_Right
  style.ButtonTextAlign = ImVec2(x: 0.5f, y: 0.5f)
  style.SelectableTextAlign = ImVec2(x: 0.0f, y: 0.0f)
  
  style.Colors[ord ImGuiCol_Text] = ImVec4(x: 1.0f, y: 1.0f, z: 1.0f, w: 1.0f)
  style.Colors[ord ImGuiCol_TextDisabled] = ImVec4(x: 0.2745098173618317f, y: 0.3176470696926117f, z: 0.4509803950786591f, w: 1.0f)
  style.Colors[ord ImGuiCol_WindowBg] = ImVec4(x: 0.0784313753247261f, y: 0.08627451211214066f, z: 0.1019607856869698f, w: 1.0f)
  style.Colors[ord ImGuiCol_ChildBg] = ImVec4(x: 0.09411764889955521f, y: 0.1019607856869698f, z: 0.1176470592617989f, w: 1.0f)
  style.Colors[ord ImGuiCol_PopupBg] = ImVec4(x: 0.0784313753247261f, y: 0.08627451211214066f, z: 0.1019607856869698f, w: 1.0f)
  style.Colors[ord ImGuiCol_Border] = ImVec4(x: 0.1568627506494522f, y: 0.168627455830574f, z: 0.1921568661928177f, w: 1.0f)
  style.Colors[ord ImGuiCol_BorderShadow] = ImVec4(x: 0.0784313753247261f, y: 0.08627451211214066f, z: 0.1019607856869698f, w: 1.0f)
  style.Colors[ord ImGuiCol_FrameBg] = ImVec4(x: 0.1676214188337326f, y: 0.1842878460884094f, z: 0.2231759428977966f, w: 1.0f)
  style.Colors[ord ImGuiCol_FrameBgHovered] = ImVec4(x: 0.1568627506494522f, y: 0.168627455830574f, z: 0.1921568661928177f, w: 1.0f)
  style.Colors[ord ImGuiCol_FrameBgActive] = ImVec4(x: 0.1568627506494522f, y: 0.168627455830574f, z: 0.1921568661928177f, w: 1.0f)
  style.Colors[ord ImGuiCol_TitleBg] = ImVec4(x: 0.0470588244497776f, y: 0.05490196123719215f, z: 0.07058823853731155f, w: 1.0f)
  style.Colors[ord ImGuiCol_TitleBgActive] = ImVec4(x: 0.0470588244497776f, y: 0.05490196123719215f, z: 0.07058823853731155f, w: 1.0f)
  style.Colors[ord ImGuiCol_TitleBgCollapsed] = ImVec4(x: 0.0784313753247261f, y: 0.08627451211214066f, z: 0.1019607856869698f, w: 1.0f)
  style.Colors[ord ImGuiCol_MenuBarBg] = ImVec4(x: 0.09803921729326248f, y: 0.105882354080677f, z: 0.1215686276555061f, w: 1.0f)
  style.Colors[ord ImGuiCol_ScrollbarBg] = ImVec4(x: 0.0470588244497776f, y: 0.05490196123719215f, z: 0.07058823853731155f, w: 1.0f)
  style.Colors[ord ImGuiCol_ScrollbarGrab] = ImVec4(x: 0.1176470592617989f, y: 0.1333333402872086f, z: 0.1490196138620377f, w: 1.0f)
  style.Colors[ord ImGuiCol_ScrollbarGrabHovered] = ImVec4(x: 0.1568627506494522f, y: 0.168627455830574f, z: 0.1921568661928177f, w: 1.0f)
  style.Colors[ord ImGuiCol_ScrollbarGrabActive] = ImVec4(x: 0.1176470592617989f, y: 0.1333333402872086f, z: 0.1490196138620377f, w: 1.0f)
  style.Colors[ord ImGuiCol_CheckMark] = ImVec4(x: 1.0f, y: 0.4980392456054688f, z: 0.4980392456054688f, w: 1.0f)
  style.Colors[ord ImGuiCol_SliderGrab] = ImVec4(x: 0.6695278882980347f, y: 0.3333271741867065f, z: 0.3333271741867065f, w: 1.0f)
  style.Colors[ord ImGuiCol_SliderGrabActive] = ImVec4(x: 1.0f, y: 0.7960784435272217f, z: 0.4980392158031464f, w: 1.0f)
  style.Colors[ord ImGuiCol_Button] = ImVec4(x: 0.1176470592617989f, y: 0.1333333402872086f, z: 0.1490196138620377f, w: 1.0f)
  style.Colors[ord ImGuiCol_ButtonHovered] = ImVec4(x: 0.1803921610116959f, y: 0.1882352977991104f, z: 0.196078434586525f, w: 1.0f)
  style.Colors[ord ImGuiCol_ButtonActive] = ImVec4(x: 0.1529411822557449f, y: 0.1529411822557449f, z: 0.1529411822557449f, w: 1.0f)
  style.Colors[ord ImGuiCol_Header] = ImVec4(x: 0.1411764770746231f, y: 0.1647058874368668f, z: 0.2078431397676468f, w: 1.0f)
  style.Colors[ord ImGuiCol_HeaderHovered] = ImVec4(x: 0.105882354080677f, y: 0.105882354080677f, z: 0.105882354080677f, w: 1.0f)
  style.Colors[ord ImGuiCol_HeaderActive] = ImVec4(x: 0.0784313753247261f, y: 0.08627451211214066f, z: 0.1019607856869698f, w: 1.0f)
  style.Colors[ord ImGuiCol_Separator] = ImVec4(x: 0.1294117718935013f, y: 0.1490196138620377f, z: 0.1921568661928177f, w: 1.0f)
  style.Colors[ord ImGuiCol_SeparatorHovered] = ImVec4(x: 0.1568627506494522f, y: 0.1843137294054031f, z: 0.250980406999588f, w: 1.0f)
  style.Colors[ord ImGuiCol_SeparatorActive] = ImVec4(x: 0.1568627506494522f, y: 0.1843137294054031f, z: 0.250980406999588f, w: 1.0f)
  style.Colors[ord ImGuiCol_ResizeGrip] = ImVec4(x: 0.1450980454683304f, y: 0.1450980454683304f, z: 0.1450980454683304f, w: 1.0f)
  style.Colors[ord ImGuiCol_ResizeGripHovered] = ImVec4(x: 1.0f, y: 0.4980392456054688f, z: 0.4980392456054688f, w: 1.0f)
  style.Colors[ord ImGuiCol_ResizeGripActive] = ImVec4(x: 1.0f, y: 1.0f, z: 1.0f, w: 1.0f)
  style.Colors[ord ImGuiCol_Tab] = ImVec4(x: 0.0784313753247261f, y: 0.08627451211214066f, z: 0.1019607856869698f, w: 1.0f)
  style.Colors[ord ImGuiCol_TabHovered] = ImVec4(x: 0.1176470592617989f, y: 0.1333333402872086f, z: 0.1490196138620377f, w: 1.0f)
  style.Colors[ord ImGuiCol_TabSelected] = ImVec4(x: 0.1176470592617989f, y: 0.1333333402872086f, z: 0.1490196138620377f, w: 1.0f)
  # style.Colors[ord ImGuiCol_TabUnfocused] = ImVec4(x: 0.0784313753247261f, y: 0.08627451211214066f, z: 0.1019607856869698f, w: 1.0f)
  # style.Colors[ord ImGuiCol_TabUnfocusedActive] = ImVec4(x: 0.125490203499794f, y: 0.2745098173618317f, z: 0.572549045085907f, w: 1.0f)
  style.Colors[ord ImGuiCol_PlotLines] = ImVec4(x: 0.5215686559677124f, y: 0.6000000238418579f, z: 0.7019608020782471f, w: 1.0f)
  style.Colors[ord ImGuiCol_PlotLinesHovered] = ImVec4(x: 0.03921568766236305f, y: 0.9803921580314636f, z: 0.9803921580314636f, w: 1.0f)
  style.Colors[ord ImGuiCol_PlotHistogram] = ImVec4(x: 0.8823529481887817f, y: 0.6104688048362732f, z: 0.5607843399047852f, w: 1.0f)
  style.Colors[ord ImGuiCol_PlotHistogramHovered] = ImVec4(x: 1.0f, y: 0.6652360558509827f, z: 0.6652360558509827f, w: 1.0f)
  style.Colors[ord ImGuiCol_TableHeaderBg] = ImVec4(x: 0.0470588244497776f, y: 0.05490196123719215f, z: 0.07058823853731155f, w: 1.0f)
  style.Colors[ord ImGuiCol_TableBorderStrong] = ImVec4(x: 0.0470588244497776f, y: 0.05490196123719215f, z: 0.07058823853731155f, w: 1.0f)
  style.Colors[ord ImGuiCol_TableBorderLight] = ImVec4(x: 0.0f, y: 0.0f, z: 0.0f, w: 1.0f)
  style.Colors[ord ImGuiCol_TableRowBg] = ImVec4(x: 0.1176470592617989f, y: 0.1333333402872086f, z: 0.1490196138620377f, w: 1.0f)
  style.Colors[ord ImGuiCol_TableRowBgAlt] = ImVec4(x: 0.09803921729326248f, y: 0.105882354080677f, z: 0.1215686276555061f, w: 1.0f)
  style.Colors[ord ImGuiCol_TextSelectedBg] = ImVec4(x: 0.6394850015640259f, y: 0.6394786238670349f, z: 0.6394786238670349f, w: 1.0f)
  style.Colors[ord ImGuiCol_DragDropTarget] = ImVec4(x: 0.4980392158031464f, y: 0.5137255191802979f, z: 1.0f, w: 1.0f)
  # style.Colors[ord ImGuiCol_NavHighlight] = ImVec4(x: 0.2666666805744171f, y: 0.2901960909366608f, z: 1.0f, w: 1.0f)
  style.Colors[ord ImGuiCol_NavWindowingHighlight] = ImVec4(x: 0.4980392158031464f, y: 0.5137255191802979f, z: 1.0f, w: 1.0f)
  style.Colors[ord ImGuiCol_NavWindowingDimBg] = ImVec4(x: 0.1032821089029312f, y: 0.09268912672996521f, z: 0.2918455004692078f, w: 0.501960813999176f)
  style.Colors[ord ImGuiCol_ModalWindowDimBg] = ImVec4(x: 0.1136858016252518f, y: 0.1022306457161903f, z: 0.3175965547561646f, w: 0.501960813999176f)
  
  nodeStyle.Colors[ord ImNodesCol_NodeBackground] = ImVec4(x: 0.0784313753247261f, y: 0.08627451211214066f, z: 0.1019607856869698f, w: 1.0f).igColorConvertFloat4ToU32()
  nodeStyle.Colors[ord ImNodesCol_NodeBackgroundHovered] = ImVec4(x: 0.09411764889955521f, y: 0.1019607856869698f, z: 0.1176470592617989f, w: 1.0f).igColorConvertFloat4ToU32()
  nodeStyle.Colors[ord ImNodesCol_NodeBackgroundSelected] = ImVec4(x: 0.09411764889955521f, y: 0.1019607856869698f, z: 0.1176470592617989f, w: 1.0f).igColorConvertFloat4ToU32()
  nodeStyle.Colors[ord ImNodesCol_NodeOutline] = ImVec4(x: 0.1568627506494522f, y: 0.168627455830574f, z: 0.1921568661928177f, w: 1.0f).igColorConvertFloat4ToU32()
  nodeStyle.Colors[ord ImNodesCol_TitleBar] = ImVec4(x: 0.6695278882980347f / 2, y: 0.3333271741867065f / 2, z: 0.3333271741867065f / 2, w: 1.0f).igColorConvertFloat4ToU32()
  nodeStyle.Colors[ord ImNodesCol_TitleBarHovered] = ImVec4(x: 0.6695278882980347f / 1.5, y: 0.3333271741867065f / 1.5, z: 0.3333271741867065f / 1.5, w: 1.0f).igColorConvertFloat4ToU32()
  nodeStyle.Colors[ord ImNodesCol_TitleBarSelected] = ImVec4(x: 0.6695278882980347f, y: 0.3333271741867065f, z: 0.3333271741867065f, w: 1.0f).igColorConvertFloat4ToU32()
  nodeStyle.Colors[ord ImNodesCol_GridBackground] = ImVec4(x: 0.0470588244497776f, y: 0.05490196123719215f, z: 0.07058823853731155f, w: 1.0f).igColorConvertFloat4ToU32()
  nodeStyle.Colors[ord ImNodesCol_Link] = ImVec4(x: 0.6695278882980347f, y: 0.3333271741867065f, z: 0.3333271741867065f, w: 1.0f).igColorConvertFloat4ToU32()
  nodeStyle.Colors[ord ImNodesCol_MiniMapLink] = ImVec4(x: 0.6695278882980347f, y: 0.3333271741867065f, z: 0.3333271741867065f, w: 1.0f).igColorConvertFloat4ToU32()
  nodeStyle.Colors[ord ImNodesCol_LinkHovered] = ImVec4(x: 0.6695278882980347f * 1.5, y: 0.3333271741867065f * 1.5, z: 0.3333271741867065f * 1.5, w: 1.0f).igColorConvertFloat4ToU32()
  nodeStyle.Colors[ord ImNodesCol_LinkSelected] = ImVec4(x: 0.6695278882980347f * 1.5, y: 0.3333271741867065f * 1.5, z: 0.3333271741867065f * 1.5, w: 1.0f).igColorConvertFloat4ToU32()
  nodeStyle.Colors[ord ImNodesCol_MiniMapLinkSelected] = ImVec4(x: 0.6695278882980347f, y: 0.3333271741867065f, z: 0.3333271741867065f, w: 1.0f).igColorConvertFloat4ToU32()
  nodeStyle.Colors[ord ImNodesCol_Pin] = ImVec4(x: 0.6695278882980347f, y: 0.3333271741867065f, z: 0.3333271741867065f, w: 1.0f).igColorConvertFloat4ToU32()
  nodeStyle.Colors[ord ImNodesCol_PinHovered] = ImVec4(x: 0.6695278882980347f * 1.5, y: 0.3333271741867065f * 1.5, z: 0.3333271741867065f * 1.5, w: 1.0f).igColorConvertFloat4ToU32()

  nodeStyle.NodeBorderThickness = 2.0f
  #nodeStyle.NodePadding = ImVec2(x: 8.0f, y: 4.0f)

  #globalColorsScheme[GlobalCol_WavePrev1] = ImVec4(x: 1.0f, y: 0.7960784435272217f, z: 0.4980392158031464f, w: 1.0f)
  #globalColorsScheme[GlobalCol_WavePrevLine] = ImVec4(x: 1.0f, y: 0.7960784435272217f, z: 0.4980392158031464f, w: 1.0f)
  #globalColorsScheme[GlobalCol_WavePrev2] = ImVec4(x: 0.6695278882980347f, y: 0.3333271741867065f, z: 0.3333271741867065f, w: 0.0f)
  
  globalColorsScheme[GlobalCol_WavePrev1] = ImVec4(x: 0.6695278882980347f, y: 0.3333271741867065f, z: 0.3333271741867065f, w: 1.0f)
  globalColorsScheme[GlobalCol_WavePrevLine] = ImVec4(x: 0.6695278882980347f, y: 0.3333271741867065f, z: 0.3333271741867065f, w: 1.0f)
  globalColorsScheme[GlobalCol_WavePrev2] = ImVec4(x: 0.7f, y: 0.3f, z: 0.5f, w: 0.0f)

  globalColorsScheme[GlobalCol_HoveredNodeOutline] = ImVec4(x: 0.6695278882980347f / 1.5, y: 0.3333271741867065f / 1.5, z: 0.3333271741867065f / 1.5, w: 1.0f)
  globalColorsScheme[GlobalCol_SelectedNodeOutline] = ImVec4(x: 0.6695278882980347f, y: 0.3333271741867065f, z: 0.3333271741867065f, w: 1.0f)

  globalToggleConfig.Off.Palette[].Frame = igGetStyleColorVec4(ord ImGuiCol_FrameBg)[]
  globalToggleConfig.Off.Palette[].FrameHover = igGetStyleColorVec4(ord ImGuiCol_FrameBgHovered)[]
  globalToggleConfig.Off.Palette[].Knob = ImVec4(x: 0.1676214188337326f * 2, y: 0.1842878460884094f * 2, z: 0.2231759428977966f * 2, w: 1.0f)
  globalToggleConfig.Off.Palette[].KnobHover = ImVec4(x: 0.1676214188337326f * 2.5, y: 0.1842878460884094f * 2.5, z: 0.2231759428977966f * 2.5, w: 1.0f)
  globalToggleConfig.On.Palette[].Frame = ImVec4(x: 0.6695278882980347f / 1.5, y: 0.3333271741867065f / 1.5, z: 0.3333271741867065f / 1.5, w: 1.0f)
  globalToggleConfig.On.Palette[].FrameHover = ImVec4(x: 0.6695278882980347f, y: 0.3333271741867065f, z: 0.3333271741867065f, w: 1.0f)
  globalToggleConfig.On.Palette[].Knob = ImVec4(x: 1.0f * 0.9, y: 0.7960784435272217f * 0.9, z: 0.4980392158031464f * 0.9, w: 1.0f)
  globalToggleConfig.On.Palette[].KnobHover = ImVec4(x: 1.0f, y: 0.7960784435272217f, z: 0.4980392158031464f, w: 1.0f)