lib Modserver
  type Servlet = Void*

  fun get_arg(s: Servlet*, name: UInt8*) : UInt8*
  fun get_method(s: Servlet*) : UInt8*
  fun get_header(s: Servlet*, key: UInt8*) : UInt8*
  fun set_status(s: Servlet*, status: Int32) : Void
  fun set_header(s: Servlet*, key: UInt8*, value: UInt8*) : Void
  fun rwrite(s: Servlet*, buffer: UInt8*, length: UInt32) : Void
  fun rprintf(s: Servlet*, format: UInt8*, ...) : Int32
  fun rflush(s: Servlet*) : Void
end
