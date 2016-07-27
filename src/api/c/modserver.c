// C99
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
// Lua
#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>

/*
Users of the API must not have to manage the Lua stack. The API implementation is 
responsible for managing the Lua stack.
*/

const char *get_arg(lua_State *l, const char *name)
{
  lua_getfield(l, -1, "get_arg");
  lua_pushvalue(l, 1);
  lua_pushstring(l, name);
  lua_call(l, 2, 1);
  const char *arg = lua_tostring(l, -1);
  /*
  Push another copy of the servlet ref over the string arg. This keeps the arg ref alive 
  until after servlet:run() returns.
  */
  lua_pushvalue(l, 1);
  return arg;
}

const char *get_method(lua_State *l)
{
  lua_getfield(l, -1, "get_method");
  lua_pushvalue(l, 1);
  lua_call(l, 1, 1);
  const char *method = luaL_checkstring(l, -1);
  lua_pushvalue(l, 1);
  return method;
}

const char *get_header(lua_State *l, const char *name)
{
  lua_getfield(l, -1, "get_header");
  lua_pushvalue(l, 1);
  lua_pushstring(l, name);
  lua_call(l, 2, 1);
  const char *arg = lua_tostring(l, -1);
  lua_pushvalue(l, 1);
  return arg;
}

void set_header(lua_State *l, const char *name, const char *value)
{
  lua_getfield(l, -1, "set_header");
  lua_pushvalue(l, 1);
  lua_pushstring(l, name);
  lua_pushstring(l, value);
  lua_call(l, 3, 0);
}

// the default status is 200
void set_status(lua_State *l, int status)
{
  lua_getfield(l, -1, "set_status");
  lua_pushvalue(l, 1);
  lua_pushnumber(l, status);
  // servlet.set_status(self, status)
  lua_call(l, 2, 0);
}

void rwrite(lua_State *l, const char *buffer, size_t length)
{
  lua_getfield(l, -1, "rwrite");
  lua_pushvalue(l, 1);
  lua_pushlstring(l, buffer, length);
  lua_call(l, 2, 0);
}

static void write_status_line_and_headers(lua_State *l)
{
  lua_getfield(l, -1, "write_status_line_and_headers");
  lua_pushvalue(l, 1);
  lua_call(l, 1, 0);
}

static FILE* get_clientfd_write(lua_State *l)
{
  lua_getfield(l, -1, "clientfd_write");
  luaL_Stream *stream = luaL_checkudata(l, -1, LUA_FILEHANDLE);
  FILE *f = stream->f;
  lua_pop(l, 1);
  return f;
}

int rprintf(lua_State *l, const char *format, ...)
{
  lua_getfield(l, -1, "response_headers_written");
  int response_headers_written = lua_toboolean(l, -1);
  lua_pop(l, 1);
  if (!response_headers_written)
  {
    write_status_line_and_headers(l);
  }
  FILE *f = get_clientfd_write(l);
  int ret;
  va_list ap0, ap1;
  va_start(ap0, format);
  va_copy(ap1, ap0);
  // Get the length of the output without writing anything.
  // Per C99: "If n is zero, nothing is written, and s may be a null pointer."
  int len = vsnprintf(NULL, 0, format, ap0);
  va_end(ap0);
  if (strcmp(get_method(l), "HEAD") == 0)
  {
    return len;
  }
  lua_getfield(l, -1, "response_headers");
  lua_getfield(l, -1, "content-length");
  int chunked = !lua_toboolean(l, -1);
  lua_pop(l, 2);
  if (chunked)
  {
    ret = fprintf(f, "%X\r\n", len);
  }
  ret = vfprintf(f, format, ap1);
  va_end(ap1);
  if (chunked)
  {
    fprintf(f, "\r\n");
  }
  return ret;
}

void rflush(lua_State *l)
{
  lua_getfield(l, -1, "rflush");
  lua_pushvalue(l, 1);
  lua_call(l, 1, 0);
}
