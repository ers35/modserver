#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>

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
    luaL_pushresult(&b);
    return (lua_rawlen(l, -1) > 0);
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
