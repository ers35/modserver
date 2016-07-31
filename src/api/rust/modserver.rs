// Rust experts: please provide feedback if there is a better way to accomplish this.

use std::ffi::{CStr, CString};

pub mod cmodserver;

pub type Servlet = cmodserver::Servlet;

pub fn get_arg(s: *mut cmodserver::Servlet, name: &str) -> Option<String> {
  unsafe {
    let c_name = CString::new(name).unwrap();
    let c_arg = cmodserver::get_arg(s, c_name.as_ptr());
    if !c_arg.is_null() {
      let arg = CStr::from_ptr(c_arg);
      return Some(arg.to_string_lossy().into_owned());
    }
    else {
      return None;
    }
  }
}

pub fn get_method(s: *mut cmodserver::Servlet) -> String {
  unsafe {
    let c_method = cmodserver::get_method(s);
    let method = CStr::from_ptr(c_method);
    return method.to_string_lossy().into_owned();
  }
}

pub fn get_header(s: *mut cmodserver::Servlet, name: &str) -> Option<String> {
  unsafe {
    let c_name = CString::new(name).unwrap();
    let c_value = cmodserver::get_header(s, c_name.as_ptr());
    if !c_value.is_null() {
      let value = CStr::from_ptr(c_value);
      return Some(value.to_string_lossy().into_owned());
    }
    else {
      return None;
    }
  }
}

pub fn set_status(s: *mut cmodserver::Servlet, status: u32) {
  unsafe {
    cmodserver::set_status(s, status);
  }
}

pub fn set_header(s: *mut cmodserver::Servlet, name: &str, value: &str) {
  unsafe {
    let c_name = CString::new(name).unwrap();
    let c_value = CString::new(value).unwrap();
    cmodserver::set_header(s, c_name.as_ptr(), c_value.as_ptr());
  }
}

pub fn rwrite(s: *mut cmodserver::Servlet, buffer: Vec<u8>) -> usize {
  unsafe {
    let length = buffer.len();
    let c_buffer = CString::from_vec_unchecked(buffer);
    let ret = cmodserver::rwrite(s, c_buffer.as_ptr(), length);
    return ret;
  }
}

pub fn rflush(s: *mut cmodserver::Servlet) {
  unsafe {
    cmodserver::rflush(s);
  }
}

// https://doc.rust-lang.org/book/ffi.html
