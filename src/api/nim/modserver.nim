type
  Servlet {.pure, final.} = object
  PServlet* = ptr Servlet

proc get_arg*(s: PServlet, name: cstring): cstring{.cdecl, importc: "get_arg".}
proc get_method*(s: PServlet): cstring{.cdecl, importc: "get_method".}
proc get_header*(s: PServlet, key: cstring): cstring{.cdecl, importc: "get_header".}
proc set_status*(s: PServlet, status: int32): void{.cdecl, importc: "set_status".}
proc set_header*(s: PServlet, key: cstring, value: cstring): void{.cdecl, importc: "set_header".}
proc rwrite*(s: PServlet, buffer: cstring, length: int): void{.cdecl, importc: "rwrite".}
proc rprintf*(s: PServlet, format: cstring): int32{.cdecl, varargs, importc: "rprintf".}
proc rflush*(s: PServlet): void{.cdecl, importc: "rflush".}

# https://github.com/nim-lang/Nim/blob/master/lib/wrappers/sqlite3.nim
