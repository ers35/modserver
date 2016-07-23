#include "modserver.h"
#include "unistd.h"

int run(servlet *s)
{
  set_header(s, "Content-Type", "text/plain; charset=UTF-8");
  for (int count = 0; count < 5; ++count)
  {
    rprintf(s, "count: %i\n", count);
    // Without the rflush() the user would have to wait 5 seconds to see any output.
    rflush(s);
    sleep(1);
  }
  rprintf(s, "done\n");
  return 0;
}
