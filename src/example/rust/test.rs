// Rust experts: please provide feedback if there is a better way to accomplish this.

#![crate_type = "dylib"]

#[path="../../api/rust/modserver.rs"]
pub mod modserver;
use modserver::*;

#[no_mangle]
pub extern "C" fn run(s: *mut Servlet) -> u32 {
  set_status(s, 200);
  set_header(s, "Content-Type", "text/plain; charset=UTF-8");
  match get_arg(s, "arg") {
    Some(x) => { rwrite(s, x.into_bytes()); },
    None  => { }
  }
  let method = get_method(s);
  let bytes = method.into_bytes();
  rwrite(s, bytes);
  match get_header(s, "User-Agent") {
    Some(x) => { rwrite(s, x.into_bytes()); },
    None  => { }
  }
  rflush(s);
  return 0;
}
