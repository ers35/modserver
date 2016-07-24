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

func to_ptr(str string) (unsafe.Pointer) {
  str_slice := []byte(str)
  str_ptr := unsafe.Pointer(&str_slice[0])
  return str_ptr
}

func Get_arg(s unsafe.Pointer, name string) (string) {
  name_ptr := to_ptr(name)
  arg := C.get_arg((*C.servlet)(s), (*C.char)(name_ptr))
  arg_string := C.GoString(arg)
  return arg_string
}

func Get_method(s unsafe.Pointer) (string) {
  method := C.get_method((*C.servlet)(s))
  method_string := C.GoString(method)
  return method_string
}

func Get_header(s unsafe.Pointer, key string) (string) {
  key_ptr := to_ptr(key)
  value := C.get_header((*C.servlet)(s), (*C.char)(key_ptr))
  value_string := C.GoString(value)
  return value_string
}

func Set_status(s unsafe.Pointer, status int32) {
  C.set_status((*C.servlet)(s), (C.int)(status))
}

func Set_header(s unsafe.Pointer, key string, value string) {
  key_ptr := to_ptr(key)
  value_ptr := to_ptr(value)
  C.set_header((*C.servlet)(s), (*C.char)(key_ptr), (*C.char)(value_ptr))
}

func Set_content_length(s unsafe.Pointer, length uint) {
  C.set_content_length((*C.servlet)(s), (C.size_t)(length))
}

func Rwrite(s unsafe.Pointer, buffer string) {
  buffer_ptr := to_ptr(buffer)
  C.rwrite((*C.servlet)(s), (*C.char)(buffer_ptr), C.size_t(len(buffer)))
}

func Rflush(s unsafe.Pointer) {
  C.rflush((*C.servlet)(s))
}

// https://github.com/golang/go/wiki/cgo
// https://github.com/golang/go/issues/14985
