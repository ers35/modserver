package api

/*
#cgo CFLAGS: -I../../../c
#cgo darwin LDFLAGS: -Wl,-undefined -Wl,dynamic_lookup
#cgo !darwin LDFLAGS: -Wl,-unresolved-symbols=ignore-all
#include "modserver.h"
*/
import "C"

import "unsafe"

//type Servlet C.servlet
//type Servlet unsafe.Pointer

func Rwrite(s unsafe.Pointer, buffer string) {
  reply := []byte(buffer)
  reply_ptr := unsafe.Pointer(&reply[0])
  C.rwrite((*C.servlet)(s), (*C.char)(reply_ptr), C.size_t(len(reply)))
}

// https://github.com/golang/go/wiki/cgo
// https://github.com/golang/go/issues/14985
