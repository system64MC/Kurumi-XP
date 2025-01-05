import math
import imguin/[glfw_opengl,cimgui]

proc moduloFix*(a, b: float64): float64 =
    return ((a mod b) + b) mod b

proc linearInterpolation*(x1, y1, x2, y2, x: float64): float64 =
    let slope = (y2 - y1) / (x2 - x1)
    return y1 + (slope * (x - x1))

type
  Vec2*[T] = object
    x*, y*: T

proc `+`*(a: ImVec2, b: ImVec2): ImVec2 =
  return ImVec2(x: a.x + b.x, y: a.y + b.y)

proc `*`*(a: ImVec2, s: float): ImVec2 =
  return ImVec2(x: a.x * s, y: a.y * s)

proc flushToZero*(n: SomeFloat): float64 =
  if(abs(n) < 1e-15): result = 0.0 else: result = n

const IM_COL32_R_SHIFT  =  16
const IM_COL32_G_SHIFT  =  8
const IM_COL32_B_SHIFT  =  0
const IM_COL32_A_SHIFT  =  24
const IM_COL32_A_MASK   =  0xFF000000

proc IM_COL32(R, G, B, A: uint8): uint32 =
  return (uint32(A) shl IM_COL32_A_SHIFT) or
  (uint32(B) shl IM_COL32_B_SHIFT) or
  (uint32(G) shl IM_COL32_G_SHIFT) or
  (uint32(R) shl IM_COL32_R_SHIFT)
proc colorLerp*(col_a, col_b: uint32, t: float): uint32 =
  # Ensure t is in the range [0, 1]
  var t = t
  if (t < 0.0f): t = 0.0f
  if (t > 1.0f): t = 1.0f

  # Extract RGBA components from the first color
  let r1 = float((col_a shr IM_COL32_R_SHIFT) and 0xFF)
  let g1 = float((col_a shr IM_COL32_G_SHIFT) and 0xFF)
  let b1 = float((col_a shr IM_COL32_B_SHIFT) and 0xFF)
  let a1 = float((col_a shr IM_COL32_A_SHIFT) and 0xFF)

  # Extract RGBA components from the second color
  let r2 = float((col_b shr IM_COL32_R_SHIFT) and 0xFF)
  let g2 = float((col_b shr IM_COL32_G_SHIFT) and 0xFF)
  let b2 = float((col_b shr IM_COL32_B_SHIFT) and 0xFF)
  let a2 = float((col_b shr IM_COL32_A_SHIFT) and 0xFF)

  # Perform linear interpolation for each component
  let r = uint8(r1 + (r2 - r1) * t)
  let g = uint8(g1 + (g2 - g1) * t)
  let b = uint8(b1 + (b2 - b1) * t)
  let a = uint8(a1 + (a2 - a1) * t)

  return IM_COL32(r, g, b, a)