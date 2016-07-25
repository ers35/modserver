module api;

extern (C)
{
  struct servlet;
  const(char)* get_arg(servlet *s, const char *name);
  const(char)* get_method(servlet *s);
  const(char)* get_header(servlet *s, const char *key);
  void set_status(servlet *s, int status);
  void set_header(servlet *s, const char *key, const char *value);
  void rwrite(servlet *s, const char *buffer, size_t length);
  int rprintf(servlet *s, const char *format, ...);
  void rflush(servlet *s);
}

// https://dlang.org/dll-linux.html
// https://dlang.org/spec/interfaceToC.html
