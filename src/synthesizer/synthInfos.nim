import ../utils

type
  SynthInfos* = ref object
    waveDims*: Vec[int32] = Vec[int32](x: 32, y: 15)
    oversample*: int32 = 4
    macroLen*: int32 = 64
    macroFrame*: int32 = 0
    lsfr*: uint16 = 0b01001_1010_1011_1010