import modules
import modulesEnum
import ../../globals
import ../../maths

proc summon(moduleType: ModuleType, position: Vec2[float32]): ModuleSynthGeneric =
  case moduleType:
  of MODULE_OSCILLATOR: return ModuleSynthOscillator.summon(position)
  of MODULE_AMPLIFIER: return ModuleSynthAmplifier.summon(position)
  of MODULE_PHASE_MOD: return ModuleSynthPhaseMod.summon(position)
  of MODULE_EXPONENTER: return ModuleSynthExponenter.summon(position)
  of MODULE_PHASE: return ModuleSynthPhase.summon(position)
  of MODULE_AMP_MOD: return ModuleSynthAmpMod.summon(position)
  of MODULE_EXP_MOD: return ModuleSynthExpMod.summon(position)
  of MODULE_MIXER: return ModuleSynthMixer.summon(position)
  of MODULE_SPLITTER: return ModuleSynthSplitter.summon(position)
  of MODULE_MINIMAX: return ModuleSynthMiniMax.summon(position)
  of MODULE_UNISON: return ModuleSynthUnison.summon(position)
  of MODULE_MORPHER: return ModuleSynthMorpher.summon(position)
  of MODULE_RECTIFIER: return ModuleSynthRectifier.summon(position)
  of MODULE_ABSOLUTER: return ModuleSynthAbsoluter.summon(position)
  of MODULE_INVERTER: return ModuleSynthInverter.summon(position)
  of MODULE_HARMONICS: return ModuleSynthHarmonics.summon(position)
  of MODULE_SILM: return ModuleSynthSILM.summon(position)
  of MODULE_WAVEFOLDER: return ModuleSynthWaveFolder.summon(position)
  of MODULE_AMPMASK: return ModuleSynthAmpMask.summon(position)
  of MODULE_PHASEMASK: return ModuleSynthPhaseMask.summon(position)
  of MODULE_OUTPUT: quit("Cannot summon output module")
  of MODULE_NULL: quit("Cannot summon NULL module")
  of MODULE_END: quit("Cannot summon END module")

proc findFreeSlot(moduleList: var array[MAX_MODULES, ModuleSynthGeneric]): int =
  for i in 0..<MAX_MODULES:
    if(moduleList[i] == nil): return i
  return -1

proc summonToList*(moduleType: ModuleType, moduleList: var array[MAX_MODULES, ModuleSynthGeneric], position: Vec2[float32]): int =
  let freeSlot = findFreeSlot(moduleList)
  if(freeSlot == -1): return -1
  moduleList[freeSlot] = summon(moduleType, position)
  return freeSlot