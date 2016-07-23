package main

import api "modserver"
import "C"
import "unsafe"

//export run
func run(s unsafe.Pointer) int {
  api.Rwrite(s, "hello from Go")
  return 0
}

func main() {}
