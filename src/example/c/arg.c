#include "modserver.h"

int run(servlet *s)
{
  const char *name = get_arg(s, "name");
  rprintf(s, "hello, %s", name ? name : "no name");
  return 0;
}
