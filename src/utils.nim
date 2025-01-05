type
  Vec*[T] = object
    x*, y*: T

  Link* = int32

  PinConnection* = object
    moduleIndex*: int16
    pinIndex*: int16

  PinConnectionSmall* = object
    moduleIndex*: uint8
    pinIndex*: uint8

  ModuleLink* = object
    source*: PinConnectionSmall
    dest*: PinConnectionSmall

  Adsr* = object
    sample*: seq[int16] = @[0]
    mac*: seq[byte] = @[255]
    macString*: string = "255"
    start*    : float32
    delay*    : int32
    attack*   : int32
    peak*     : float32
    hold*     : int32
    decay*    : int32
    sustain*  : float32
    attack2*  : int32
    peak2*    : float32
    decay2*   : int32
    sustain2* : float32
    sampleFreq*: float32
    mode*: uint8

proc `moduleIndex`*(link: Link): int32 =
  return (link) and 0xFF

proc `pinIndex`*(link: Link): int32 =
  return (link shr 8) and 0b1111

proc new*(_: typedesc[Link], moduleIndex: int32, pinIndex: int32, isOutput: bool): Link =
  return (moduleIndex and 0xFF) or (((pinIndex and 0b01111) or isOutput.int32 shl 4) shl 8)

# proc unsetOutput*(link: var Link) =
#   link = link and 0b1111_1111_1111


const OUTPUT_START* = 0b10000_0000_0000
proc unsetOutput*(link: Link): Link =
  return link and (0xFFF)

proc setOutput*(link: Link): Link =
  return link or 0x1000

proc createLink*(source: PinConnection, dest: PinConnection): ModuleLink =
  let sourceSmall = PinConnectionSmall(moduleIndex: source.moduleIndex.uint8, pinIndex: source.pinIndex.uint8 or 0b1000_0000)
  let destSmall = PinConnectionSmall(moduleIndex: dest.moduleIndex.uint8, pinIndex: dest.pinIndex.uint8)
  return ModuleLink(source: sourceSmall, dest: destSmall)

proc createSmallPinConnection*(c: PinConnection, setOutput: bool): PinConnectionSmall =
  return PinConnectionSmall(moduleIndex: c.moduleIndex.uint8, pinIndex: if(setOutput): c.pinIndex.uint8 or 0b1000_0000 else: c.pinIndex.uint8)

proc createSmallPinConnection*(m: uint8, p: uint8, isOutput: bool): PinConnectionSmall =
  return PinConnectionSmall(moduleIndex: m, pinIndex: if(isOutput): p or 0b1000_0000 else: p)

proc toInt32*(c: PinConnectionSmall): int32 =
  return (cast[uint16](c)).int32

proc toInt32*(l: ModuleLink): int32 =
  return (cast[uint32](l)).int32

proc toModuleLink*(l: int32): ModuleLink =
  return cast[ModuleLink](l)

proc toSmallPinConnection*(p: int32): PinConnectionSmall =
  return cast[PinConnectionSmall](p)
# proc `moduleIndex=`*(link: var Link, index: int32) =
#   link = (link and 0xFF_FF_FF_00'i32) or (index)


# proc `pinIndex=`*(link: var Link, index: int32) =
#   link = (link and 0xff00) or index




import strutils
import maths
method refreshAdsr*(env: ptr Adsr) {.base.} =
    env.mac = @[]
    for num in env.macString.split:
        try:
            let smp = parseUInt(num).uint8
            env.mac.add(smp)
        except ValueError:
            continue
    if env.mac.len == 0:
        env.mac = @[255]

import globals
proc doAdsr*(env: Adsr, macFrame: int32): float64 =
    let mac = macFrame.float64
    # let env = envelope

    case env.mode:
    of 0:
        return env.peak
    of 1:

        let delayEnd = env.delay
        let attackEnd = env.attack + delayEnd
        let holdEnd = env.hold + attackEnd
        let decayEnd = env.decay + holdEnd
        let attack2End = env.attack2 + decayEnd
        let decay2End = env.decay2 + attack2End

        # Delay
        if(env.delay > 0 and macFrame <= delayEnd):
            return env.start              

        # Attack
        if(env.attack > 0 and macFrame >= delayEnd and macFrame <= attackEnd):
            if(env.attack <= 0):
                return env.peak
            return linearInterpolation(delayEnd.float64, env.start.float64, attackEnd.float64, env.peak.float64, mac)
        
        # Hold
        if(env.hold > 0 and macFrame >= attackEnd and macFrame <= holdEnd):
            return env.peak

        # Decay and sustain
        if(env.decay > 0 and macFrame >= holdEnd and macFrame <= decayEnd):
            if(env.decay <= 0):
                return (env.sustain.float64)
            return linearInterpolation(holdEnd.float64, env.peak.float64, decayEnd.float64, env.sustain.float64, mac)
        
        # Attack2
        if(env.attack2 > 0 and macFrame >= decayEnd and macFrame <= attack2End):
            if(env.attack2 < 0):
                return (env.peak2.float64)
            return linearInterpolation(decayEnd.float64, env.sustain.float64, attack2End.float64, env.peak2.float64, mac)

        # Decay2 and sustain2
        if(env.decay2 > 0 and macFrame >= attack2End and macFrame <= decay2End):
            if(env.attack2 < 0):
                return (env.sustain2.float64)
            return linearInterpolation(attack2End.float64, env.peak2.float64, decay2End.float64, env.sustain2.float64, mac)

        return env.sustain2

    of 2:
        if(env.mac.len == 0): return env.peak
        return env.peak * volROM[env.mac[min(macFrame, env.mac.len - 1)]]
    else:
        return 0.0


