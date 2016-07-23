import modserver;

extern (C) int run(servlet *s)
{
  string reply = "hello from D";
  rwrite(s, reply.ptr, reply.length);
  return 0;
}
