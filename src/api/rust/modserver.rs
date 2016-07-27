// Rust experts: please provide feedback if there is a better way to accomplish this.

use std::os::raw::c_char;

pub enum StructServlet { }
pub type Servlet = StructServlet;

#[allow(dead_code)]
extern {
  pub fn get_arg(s: *mut Servlet, name: *const c_char) -> *const c_char;
  pub fn get_method(s: *mut Servlet) -> *const c_char;
  pub fn get_header(s: *mut Servlet, name: *const c_char) -> *const c_char;
  pub fn set_status(s: *mut Servlet, status: u32);
  pub fn set_header(s: *mut Servlet, name: *const c_char, value: *const c_char);
  pub fn rwrite(s: *mut Servlet, buffer: *const c_char, length: usize);
  pub fn rprintf(s: *mut Servlet, format: *const c_char, ...) -> i32;
  pub fn rflush(s: *mut Servlet);
}
