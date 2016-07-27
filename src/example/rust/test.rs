// Rust experts: please provide feedback if there is a better way to accomplish this.

#![crate_type = "dylib"]

#[path="../../api/rust/modserver.rs"]
mod modserver;
use modserver::*;

use std::ffi::{CString};

#[no_mangle]
pub extern "C" fn run(s: *mut Servlet) -> u32 {
  unsafe {
    set_status(s, 200);
    let key = CString::new("Content-Type").unwrap();
    let value = CString::new("text/plain; charset=UTF-8").unwrap();
    set_header(s, key.as_ptr(), value.as_ptr());
    rflush(s);
    let format = CString::new("rprintf: %i %i\n").unwrap();
    rprintf(s, format.as_ptr(), 42, 24);
  }
  return 0;
}

// https://doc.rust-lang.org/std/ffi/struct.CStr.html
