#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>

/*
Lua's file:read() function lacks a way to read a line of a limited length. That is an 
easy denial of service if the user never sends a newline.
*/
static int cutil_fgets(lua_State *l)
{
  luaL_Stream *stream = luaL_checkudata(l, -1, LUA_FILEHANDLE);
  int size = luaL_checknumber(l, -2);
  FILE *f = stream->f;
  luaL_Buffer b;
  luaL_buffinit(l, &b);
  char *p = luaL_prepbuffsize(&b, size);
  if (fgets(p, size, f) == NULL)
  {
    // discard the buffer
    luaL_pushresult(&b);
    lua_pop(l, 1);
    
    lua_pushnil(l);
    if (feof(f))
    {
      lua_pushstring(l, "EOF");
      lua_pushnil(l);
    }
    else if (ferror(f))
    {
      lua_pushstring(l, strerror(errno));
      lua_pushnumber(l, errno);
    }
    return 3;
  }
  size_t len = strlen(p);
  luaL_addsize(&b, len);
  luaL_pushresult(&b);
  return 1;
}

static const luaL_Reg cutil[] = 
{
  {"fgets", cutil_fgets},
  {NULL, NULL},
};

LUALIB_API int luaopen_cutil(lua_State *l)
{
  luaL_newlib(l, cutil);
  return 1;
}
