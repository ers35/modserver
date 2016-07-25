require "../../api/crystal/Modserver"

fun init = init(text: UInt8*): Int32
  GC.init
  LibCrystalMain.__crystal_main(0, Pointer(Pointer(UInt8)).null)
  return 0
end

fun run = run(s: Modserver::Servlet*): Int32
  Modserver.set_status(s, 200)
  Modserver.set_header(s, "Content-Type", "text/plain; charset=UTF-8")
  arg = Modserver.get_arg(s, "arg")
  if arg
    Modserver.rprintf(s, "%s\n", arg)
  end
  reply = "hello from Crystal"
  Modserver.rwrite(s, reply, reply.bytesize)
  method = Modserver.get_method(s)
  Modserver.rprintf(s, "\n%s\n", method)
  header = Modserver.get_header(s, "User-Agent")
  Modserver.rprintf(s, "%s\n", header)
  Modserver.rflush(s)
  return 0
end

# https://crystal-lang.org/docs/syntax_and_semantics/c_bindings/fun.html
# https://github.com/crystal-lang/crystal-sqlite3
# https://github.com/crystal-lang/crystal-sqlite3/blob/master/src/sqlite3/lib_sqlite3.cr
# http://stackoverflow.com/a/32921404
