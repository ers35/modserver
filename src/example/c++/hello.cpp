#include <string>
#include "modserver.h"

extern "C" int run(servlet *s)
{
  std::string reply = "hello from C++";
  rwrite(s, reply.c_str(), reply.length());
  return 0;
}
