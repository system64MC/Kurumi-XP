switch "hint","User:off"
switch "hint","Name:off"
switch "hint","XDeclaredButNotUsed:off"

#switch "app","gui" # dismiss background Window
when defined(windows):
  switch "define", "release"
  #switch "define", "danger"
  #switch "opt", "size"
  discard
else: # Linux
  switch "define", "release"
  discard

#const LTO = true # further reudce code size
const LTO = false

switch "app","gui" # dismiss background Window

#---------------------------------------
# Select static link or shared/dll link
#---------------------------------------
when defined(windows):
  const STATIC_LINK_GLFW = true
  const STATIC_LINK_CC = true      #libstd++ or libc
  switch "passL","-lgdi32 -limm32 -lcomdlg32 -luser32 -lshell32"
else: # for Linux
  const STATIC_LINK_GLFW = true
  const STATIC_LINK_CC= false

#
when STATIC_LINK_GLFW: # GLFW static link
  switch "define","glfwStaticLib"
else: # shared/dll
  when defined(windows):
    switch "passL","-lglfw3"
    switch "define", "glfwDLL"
      #switch "define","cimguiDLL"
  else:
    switch "passL","-lglfw"

when STATIC_LINK_CC: # gcc static link
    switch "passC", "-static"
    switch "passL", "-static "

# Reduce code size further
when false:
  switch "gc", "arc"
  switch "define", "useMalloc"
  switch "define", "noSignalHandler"
  #switch "panics","on"

#switch "verbosity","1"

proc commonOpt() = # for gcc and clang
#  switch "passL", "-s" # remov debug info from elf file
  switch "passC", "-ffunction-sections"
  switch "passC", "-fdata-sections"
  switch "passL", "-Wl,--gc-sections"

#const NIMCACHE = ".nimcache_" & TC
switch "nimcache", ".nimcache"

commonOpt()
switch "cc","gcc"

when LTO: # These options let link time slow while reducing code size.
  switch "define", "lto"

switch("d", "ImNodesEnable")
switch("d", "ImKnobsEnable")
when defined(opt1):
  switch("d", "release")
  switch("opt", "speed")

when defined(opt2):
  switch("d", "danger")
  switch("opt", "speed")
  --passC:"-o3 -ofast -fopt-info-vec-optimized -mavx -ffast-math -flto -fdevirtualize-at-ltrans -ftree-loop-vectorize -ftree-slp-vectorize"

--threads:"on"
when defined(windows):
  --passL:"-lstdc++"
  --gcc.exe:"x86_64-w64-mingw32-gcc"
  --gcc.linkerexe:"x86_64-w64-mingw32-gcc"
  --gcc.cpp.exe:"x86_64-w64-mingw32-g++"
  --gcc.cpp.linkerexe:"x86_64-w64-mingw32-g++"
  # --out: "kurumi_xp.exe"