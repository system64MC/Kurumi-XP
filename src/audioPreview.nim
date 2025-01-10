import miniaudio/futharkminiaudio
import miniaudio
import synthesizer/synth
import math

var phase: float64 = 0.0
const
  toneHz   = 440
  sampleHz = 44100

proc phaseAcc(length: int32): float64 =
  #let length = synth.synthInfos.waveDims.x
  let freqTable = float64(sampleHz) / float64(length)
  let playfreq = toneHz / freqTable
  phase = (phase.float64 + playfreq.float64) mod float64(length)
  return (phase mod float64(length))

proc callback(device: ptr madevice_436208034; outputBuffer: pointer; inputBuf: pointer; numSamples: mauint32_436208046): void {.cdecl.} =
  #echo device != nil
  let synth = cast[ptr Synth](device.puserdata)[]
  if(synth == nil): return

  let buf = cast[ptr UncheckedArray[int16]](outputBuffer)

  for i in 0..<(numSamples):
    if(synth.previewOn == false):
      buf[i] = 0
      continue
    let ind = phaseAcc(synth.synthInfos.waveDims.x).int32
    var sample = synth.waveOutputInt[ind mod synth.synthInfos.waveDims.x].float64
    sample = sample * (32000 / float64(synth.synthInfos.waveDims.y))
    let s2 = (((sample - 16000) * 1) * synth.previewVolume).int16
    buf[i] = s2
  #for i in 0..<numSamples:
  return

var config = madeviceconfiginit(madevicetypeplayback)
var device: madevice
proc initMiniaudio*(synth: ptr Synth) = 
  
  config.samplerate = sampleHz
  config.playback.channels = 1
  config.playback.format = maformat.maformats16
  config.puserdata = synth
  config.datacallback = callback

  if(madeviceinit(nil, config.addr, device.addr) != Masuccess):
    return

  if(madevicestart(device.addr) != Masuccess):
    return


