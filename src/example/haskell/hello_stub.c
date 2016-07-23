#include "modserver.h"
#include <HsFFI.h>

int init(servlet *s)
{
  static int argc = 1;  
  static char *argv[] = {"hello.hs.so", NULL}, **argv_ = argv;
  hs_init(&argc, &argv_);
  return 0;
}

int cleanup(servlet *s)
{
  hs_exit();
  return 0;
}
