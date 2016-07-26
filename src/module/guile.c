// C99
#include <assert.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
// Lua
#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>
// Guile Scheme
#include <libguile.h>
// Local
#include "modserver.h"

static SCM api_get_arg(SCM s_, SCM name_)
{
  servlet *s = scm_to_pointer(s_);
  char *name = scm_to_utf8_string(name_);
  const char *arg = get_arg(s, name);
  free(name);
  if (arg)
  {
    return scm_from_utf8_string(arg);
  }
  return SCM_UNSPECIFIED;
}

static SCM api_get_method(SCM s_)
{
  servlet *s = scm_to_pointer(s_);
  const char *method = get_method(s);
  if (method)
  {
    return scm_from_utf8_string(method);
  }
  return SCM_UNSPECIFIED;
}

static SCM api_get_header(SCM s_, SCM key_)
{
  servlet *s = scm_to_pointer(s_);
  char *key = scm_to_utf8_string(key_);
  const char *value = get_header(s, key);
  free(key);
  if (value)
  {
    return scm_from_utf8_string(value);
  }
  return SCM_UNSPECIFIED;
}

static SCM api_set_status(SCM s_, SCM status_)
{
  servlet *s = scm_to_pointer(s_);
  int status = scm_to_int(status_);
  set_status(s, status);
  return SCM_UNSPECIFIED;
}

static SCM api_set_header(SCM s_, SCM key_, SCM value_)
{
  servlet *s = scm_to_pointer(s_);
  char *key = scm_to_utf8_string(key_);
  char *value = scm_to_utf8_string(value_);
  set_header(s, key, value);
  free(key);
  free(value);
  return SCM_UNSPECIFIED;
}

static SCM api_rwrite(SCM s_, SCM buffer_)
{
  servlet *s = scm_to_pointer(s_);
  size_t length;
  char *str = scm_to_utf8_stringn(buffer_, &length);
  rwrite(s, str, length);
  free(str);
  return SCM_UNSPECIFIED;
}

static SCM api_rflush(SCM s_)
{
  servlet *s = scm_to_pointer(s_);
  rflush(s);
  return SCM_UNSPECIFIED;
}

static void* guile_mod_init(void *data)
{
  return NULL;
}

static int mod_init(lua_State *l)
{
  scm_init_guile();
  return 0;
}

static int servlet_run(lua_State *l)
{
  SCM run_ref = (SCM)lua_touserdata(l, lua_upvalueindex(1));
  SCM s = scm_from_pointer(l, NULL);
  scm_call_1(run_ref, s);
  return 0;
}

static int mod_load_servlet(lua_State *l)
{
  const char *path = luaL_checkstring(l, -1);
  SCM module = scm_c_define_module(path, NULL, NULL);
  SCM prev_module = scm_set_current_module(module);
  
  // TODO: don't define these functions every time for each servlet
  scm_c_define_gsubr("get_arg", 2, 0, 0, &api_get_arg);
  scm_c_define_gsubr("get_method", 1, 0, 0, &api_get_method);
  scm_c_define_gsubr("get_header", 2, 0, 0, &api_get_header);
  scm_c_define_gsubr("set_status", 2, 0, 0, &api_set_status);
  scm_c_define_gsubr("set_header", 3, 0, 0, &api_set_header);
  scm_c_define_gsubr("rwrite", 2, 0, 0, &api_rwrite);
  scm_c_define_gsubr("rflush", 1, 0, 0, &api_rflush);
  
  SCM foo = scm_c_primitive_load(path);
  SCM run_symbol = scm_c_lookup("run");
  SCM run_ref = scm_variable_ref(run_symbol);
  scm_set_current_module(prev_module);
  
  lua_newtable(l);
  lua_pushlightuserdata(l, (void*)run_ref);
  lua_pushcclosure(l, servlet_run, 1);
  lua_setfield(l, -2, "run");
  
  return 1;
}

static int mod_cleanup(lua_State *l)
{
  return 0;
}

static const luaL_Reg module_guile[] = 
{
  {"init", mod_init},
  {"load_servlet", mod_load_servlet},
  {"cleanup", mod_cleanup},
  {NULL, NULL},
};

LUALIB_API int luaopen_module_guile(lua_State *l)
{
  luaL_newlib(l, module_guile);
  return 1;
}

// https://www.gnu.org/software/guile/manual/guile.html
// https://www.gnu.org/software/guile/manual/html_node/index.html#SEC_Contents
// https://www.gnu.org/software/guile/manual/html_node/Programming-in-C.html#Programming-in-C
// https://www.gnu.org/software/guile/manual/html_node/Accessing-Modules-from-C.html
// http://www.lonelycactus.com/guilebook/seccreatingguiletoplevelvar.html
// http://www.lonelycactus.com/guilebook/secreadtoplevel.html
// http://agentzh.org/misc/code/gdb/guile/guile.c.html
// /usr/include/guile/2.0/libguile/modules.h
