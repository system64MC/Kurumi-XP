import tables
import strformat
import ../../fonts/IconsFontAudio
import ../../fonts/IconsFontAwesome6
import ../../gui/iconsUtils
import ../../systemFonts

type
  ModuleType* = enum
    MODULE_NULL,
    MODULE_OUTPUT,
    MODULE_OSCILLATOR,
    MODULE_AMPLIFIER,
    MODULE_PHASE_MOD,
    MODULE_EXPONENTER,
    MODULE_PHASE,
    MODULE_AMP_MOD,
    MODULE_EXP_MOD,
    MODULE_MIXER,
    MODULE_SPLITTER,
    MODULE_MINIMAX,
    MODULE_UNISON,
    MODULE_MORPHER,
    MODULE_RECTIFIER,
    MODULE_ABSOLUTER,
    MODULE_INVERTER,
    MODULE_HARMONICS,
    MODULE_SILM,
    MODULE_WAVEFOLDER,
    MODULE_END

import unicode
import strutils


const moduleTitles* = {
  MODULE_NULL: Text.new(FONT_AWESOME, "NULL"),
  MODULE_OUTPUT: Text.new(FONT_AWESOME, fmt"{ICON_FA_VOLUME_HIGH} Output"),
  MODULE_OSCILLATOR: Text.new(FONT_AUDIO, fmt"{ICON_FAD_MODSINE} Oscillator"),
  MODULE_AMPLIFIER: Text.new(FONT_AUDIO, fmt"{ICON_FAD_SPEAKER} Amplifier"),
  MODULE_PHASE_MOD: Text.new(FONT_AUDIO, fmt"{ICON_FAD_PRESET_AB} Phase Mod"),
  MODULE_EXPONENTER: Text.new(FONT_AWESOME, fmt"{ICON_FA_SUPERSCRIPT} Exponenter"),
  MODULE_PHASE: Text.new(FONT_AUDIO, fmt"{ICON_FAD_PHASE} Phase"),
  MODULE_AMP_MOD: Text.new(FONT_AWESOME, fmt"{ICON_FA_XMARK} Amp. Mod"),
  MODULE_EXP_MOD: Text.new(FONT_AWESOME, fmt"{ICON_FA_SUPERSCRIPT} Exp. Mod"),
  MODULE_MIXER: Text.new(FONT_AUDIO, fmt"{ICON_FAD_FILTER_SHELVING_LO} Mixer"),
  MODULE_SPLITTER: Text.new(FONT_AUDIO, fmt"{ICON_FAD_FILTER_SHELVING_HI} Splitter"),
  MODULE_MINIMAX: Text.new(FONT_AWESOME, fmt"{ICON_FA_PLUS_MINUS} MiniMax"),
  MODULE_UNISON: Text.new(FONT_AUDIO, fmt"{ICON_FAD_STEREO} Unison"),
  MODULE_MORPHER: Text.new(FONT_AWESOME, fmt"{ICON_FA_WAND_MAGIC_SPARKLES} Morpher"),
  MODULE_RECTIFIER: Text.new(FONT_AWESOME, fmt"{ICON_FA_SCISSORS} Rectifier"),
  MODULE_ABSOLUTER: Text.new(FONT_AWESOME, fmt"{ICON_FA_ARROW_UP} Absoluter"),
  MODULE_INVERTER: Text.new(FONT_AWESOME, fmt"{ICON_FA_UP_DOWN} Inverter"),
  MODULE_HARMONICS: Text.new(FONT_AUDIO, fmt"{ICON_FAD_KEYBOARD} Harmonics"),
  MODULE_SILM: Text.new(FONT_AWESOME, fmt"{ICON_FA_CALCULATOR} SILM"),
  MODULE_WAVEFOLDER: Text.new(FONT_AUDIO, fmt"{ICON_FAD_FOLDBACK} Wavefolder"),
}.toTable

export tables