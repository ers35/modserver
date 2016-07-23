import modserver

proc run(s: PServlet): int{.exportc.} =
  var reply = "hello from Nim"
  rwrite(s, reply, reply.len)
  return 0
