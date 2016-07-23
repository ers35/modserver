#include "modserver.h"

int run(servlet *s)
{
  const char reply[] = "hello from C";
  rwrite(s, reply, sizeof(reply) - 1);
  return 0;
}
