package main

import api "modserver"
import "C"
import "unsafe"

//export run
func run(s unsafe.Pointer) int {
  api.Set_status(s, 200)
  api.Set_header(s, "Content-Type", "text/plain; charset=UTF-8")
  arg := api.Get_arg(s, "arg")
  if len(arg) > 0 {
    api.Rwrite(s, arg)
    api.Rwrite(s, "\n")
  }
  method := api.Get_method(s)
  api.Rwrite(s, method)
  api.Rwrite(s, "\n")
  header := api.Get_header(s, "User-Agent")
  api.Rwrite(s, header)
  api.Rwrite(s, "\n")
  api.Rflush(s)
  return 0
}

func main() {}
