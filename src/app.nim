import events
import synthesizer/synth
import synthesizer/modules/moduleSynthGeneric
import nimgl/[opengl,glfw]
import nimpresence
import options

type
  PopupInfo* = object
    needOpen*: bool = false
    name*: string = ""
    moduleIndex*: int = -1

  KuruApp* = ref object
    synth*: Synth = Synth.create()
    events*: EventList = EventList()
    window*: GLFWWindow
    presence*: Option[Presence] = none(Presence)

    popupInfo*: PopupInfo
    modulePopupOpened*: ModuleSynthGeneric = nil

proc `isOpen`*(app: KuruApp): bool =
  return not app.window.windowShouldClose