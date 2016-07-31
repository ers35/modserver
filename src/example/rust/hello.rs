// Rust experts: please provide feedback if there is a better way to accomplish this.

#![crate_type = "dylib"]

#[path="../../api/rust/modserver.rs"]
pub mod modserver;
use modserver::*;

#[no_mangle]
pub extern "C" fn run(s: *mut Servlet) -> u32 {
  let reply = String::from("hello from Rust");
  let bytes = reply.into_bytes();
  rwrite(s, bytes);
  return 0;
}
