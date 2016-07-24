require "../../api/crystal/Modserver"

fun init = init(text: UInt8*): Int32
  GC.init
  LibCrystalMain.__crystal_main(0, Pointer(Pointer(UInt8)).null)
  return 0
end

fun run = run(s: Modserver::Servlet*): Int32
  reply = "hello from Crystal"
  Modserver.rwrite(s, reply, reply.bytesize)
  return 0
end
