#include "modserver.h"
#include <stdio.h>

int run(servlet *s)
{
  const char reply[] = "Testing setting the Content-Length header";
  char str_length[128];
  snprintf(str_length, sizeof(str_length), "%lu", sizeof(reply) - 1);
  set_header(s, "Content-Length", str_length);
  rprintf(s, reply);
  return 0;
}
