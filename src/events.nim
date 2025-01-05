type
  EventType* = enum
    EVENT_MODULE_DELETED
    EVENT_MODIFIED
    EVENT_NEED_UPDATE
    EVENT_LINK_CREATED
    EVENT_LINK_DESTROYED
    EVENT_ADD_MODULE

    EVENT_OPEN_POPUP

  EventModuleGui* = enum
    GUI_NONE
    GUI_OPEN_POPUP

  Event* = object
    eventType*: EventType
    data*: string

  EventList* = object
    events*: seq[Event] = newSeqOfCap[Event](32)

proc new*(t: typedesc[Event], eventType: EventType, data: string): Event =
  return Event(eventType: eventType, data: data)

proc flush*(eventList: var EventList) =
  eventList.events.setLen(0)

proc push*(eventList: var EventList, event: Event) =
  eventList.events.add(event)

iterator items*(eventList: EventList): Event =
  for event in eventList.events:
    yield event

proc updateCallback*(eventList: var EventList, updateDrawing: bool) =
  eventList.push(Event.new(EVENT_NEED_UPDATE, if(updateDrawing): "1" else: "0"))