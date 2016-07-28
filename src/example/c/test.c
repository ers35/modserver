#include <assert.h>
#include <string.h>
#include "modserver.h"

int run(servlet *s)
{
  const char *arg = get_arg(s, "arg");

  const char *method = get_method(s);
  assert(strcmp(method, "GET") == 0);
  
  const char *val0 = get_header(s, "User-Agent");
  const char *val1 = get_header(s, "user-agent");
  if (val0 && val1)
  {
    assert(strcmp(val0, val1) == 0);
    rprintf(s, val0);
  }
  
  set_status(s, 200);
  
  set_header(s, "Content-Type", "text/plain; charset=UTF-8");
  
  if (arg)
  {
    rprintf(s, arg);
  }
  
  rprintf(s, "The number is: %u\n", 42);
  
  rflush(s);
    
  return 0;
}
