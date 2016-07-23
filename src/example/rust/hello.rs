// Rust experts: please provide feedback if there is a better way to accomplish this.

#![crate_type = "dylib"]

#[path="../../api/rust/modserver.rs"]
mod modserver;
use modserver::*;

use std::ffi::{CString};

#[no_mangle]
pub extern "C" fn run(s: *mut Servlet) -> u32 {
  let reply = "hello from Rust";
  let creply = CString::new(reply).unwrap();
  unsafe {
    rwrite(s, creply.as_ptr(), reply.len());
  }
  return 0;
}
