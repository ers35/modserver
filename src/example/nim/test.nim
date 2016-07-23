import modserver

# http://127.0.0.1:8080/example/nim/test.nim.so?test=abc

proc run(s: PServlet): int{.exportc.} =
  set_status(s, 404)
  set_header(s, "Content-Type", "text/plain; charset=UTF-8")
  rflush(s)
  
  #set_content_length(s, 5)

  var arg = get_arg(s, "test")
  if arg != nil:
    discard rprintf(s, "get_arg(s, \"test\") = %s\n", arg)
    
  var header = get_header(s, "User-Agent")
  if header != nil:
    discard rprintf(s, "get_header(s, \"User-Agent\") = %s\n", header)
    
  var the_method = get_method(s)
  if the_method != nil:
    discard rprintf(s, "get_method(s) = %s\n", the_method)

  var reply = "hello from Nim"
  rwrite(s, reply, reply.len)
  
  rflush(s)
  
  return 0
