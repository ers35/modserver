#include <signal.h>
#include "modserver.h"

int run(servlet *s)
{
  raise(SIGSEGV);
  return 0;
}
