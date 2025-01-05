import ../globals
# import modules/moduleSynthGeneric
# import modules/moduleSynthOutput
import modules/modules
import synthInfos
import math
import ../maths

type
  Synth* = ref object
    waveOutputFloat*: array[MAX_WAVE_LENGTH * MAX_UPSAMPLE, float64]
    waveOutputInt*: array[MAX_WAVE_LENGTH, int]
    moduleList*: array[MAX_MODULES, ModuleSynthGeneric]
    synthInfos*: SynthInfos = SynthInfos()

    textAsHex*: bool = false
    textAsSigned*: bool = false
    textSequence*: bool = false

proc create*(_: typedesc[Synth]): Synth =
  let synth = Synth()
  synth.moduleList[0] = ModuleSynthOutput.summon()
  return synth

proc update(moduleList: array[MAX_MODULES, ModuleSynthGeneric]): void =
  for m in moduleList:
    if(m == nil): continue
    m.update = true
    # if(m of BoxModule):
    #   echo "Updating Box"
    #   update((m.BoxModule).moduleList)

# FUCK FLOATS!!!
#const ANTI_FLOAT_ERRORS_THRESHOLD = 1e-15
#const ANTI_FLOAT_ERRORS_THRESHOLD = epsilon
proc synthesize*(synth: Synth, redraw: bool = true) {.gcsafe.} =
  update(synth.moduleList)
  let outModule = synth.moduleList[0].ModuleSynthOutput
  #[
    Thank you Tildearrow, the Furnace dev for this hack
    to get beautiful saw waves!
  ]#
  let tildearrowAntiBadSawOffset = (0.5 / (synth.synthInfos.waveDims.x.float64 * synth.synthInfos.oversample.float64))
  let overSampleValue = 1.0/synth.synthInfos.oversample.float64
  for i in 0..<synth.synthInfos.waveDims.x:
    var sum = 0.0
    var j = 0.0
    while(j < 1):
      sum += outModule.synthesize(moduloFix(tildearrowAntiBadSawOffset + (i.float64 + j) / (synth.synthInfos.waveDims.x.float64), 1.0), outModule.inputs[0].pinIndex, synth.moduleList, synth.synthInfos) * overSampleValue
      j += overSampleValue
    synth.waveOutputFloat[i] = sum.flushToZero()

  for i in 0..<synth.synthInfos.waveDims.x:
    var value: float64 = clamp(synth.waveOutputFloat[i], -1.0, 1.0) + 1.0
    synth.waveOutputInt[i] = round(value * (synth.synthInfos.waveDims.y.float64 / 2.0)).int32