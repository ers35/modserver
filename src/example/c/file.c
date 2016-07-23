#include <stdio.h>
#include "modserver.h"

int run(servlet *s)
{
  FILE *f = fopen("example/c/file.c", "r");
  if (f)
  {
    fseek(f, 0, SEEK_END);
    long length = ftell(f);
    rewind(f);
    set_content_length(s, length);
    set_header(s, "Content-Type", "text/plain; charset=UTF-8");
    char buf[BUFSIZ];
    while (1)
    {
      size_t bytes_read = fread(buf, 1, sizeof(buf), f);
      if (bytes_read > 0)
      {
        rwrite(s, buf, bytes_read);
      }
      else
      {
        break;
      }
    }
    fclose(f);
  }
  else
  {
    rprintf(s, "file not found");
  }
  return 0;
}
