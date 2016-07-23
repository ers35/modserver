// C99
#include <assert.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
// Lua
#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>
// Ruby
#include <ruby.h>
// Local
#include "modserver.h"

static VALUE api_rwrite(VALUE self, VALUE s_, VALUE buffer)
{
  servlet *s = (servlet*)NUM2ULL(s_);
  const void *ptr = StringValuePtr(buffer);
  int length = RSTRING_LEN(buffer);
  rwrite(s, ptr, length);
  return Qnil;
}

static int mod_init(lua_State *l)
{
  int ret = ruby_setup();
  if (ret != 0)
  {
    return luaL_error(l, "ruby_setup: %d", ret);
  }
  ruby_init_loadpath();
  
  rb_define_global_function("rwrite", api_rwrite, 2);
  
  // VALUE api = rb_define_module("Api");
  // rb_define_module_function(api, "rwrite", api_rwrite, 0);
  // rb_define_const(mRUBBER, "TestConst", INT2NUM(38));
  
  return 0;
}

static int servlet_run(lua_State *l)
{
  VALUE servlet = (VALUE)lua_touserdata(l, lua_upvalueindex(1));
  VALUE ptr = ULL2NUM((unsigned long long)l);
  rb_funcall(servlet, rb_intern("call"), 1, ptr);
  return 0;
}

static int mod_load_servlet(lua_State *l)
{
  const char *path = luaL_checkstring(l, -1);
  
  int ok = luaL_loadstring(l, 
  "local f = io.open(...)\n"
  "local str = f:read([[*all]])\n"
  "f:close()\n"
  "str = str .. [[$servlet_run = lambda {|s| run(s) }]]\n"
  "return str\n"
  );
  if (ok != LUA_OK)
  {
    return luaL_error(l, lua_tostring(l, -1));
  }
  lua_pushstring(l, path);
  lua_call(l, 1, 1);
  const char *servlet_rb = luaL_checkstring(l, -1);
  
  // puts(servlet_rb);
  
  int status;
  VALUE result;
  result = rb_eval_string_protect(servlet_rb, &status);
  if (status != 0)
  {
    VALUE rbError = rb_funcall(rb_gv_get("$!"), rb_intern("message"), 0);
    return luaL_error(l, "rb_load_protect: %s", StringValuePtr(rbError));
  }
  VALUE servlet = rb_gv_get("$servlet_run");
  // printf("%lu\n", servlet);
  
  lua_newtable(l);
  lua_pushlightuserdata(l, (void*)servlet);
  lua_pushcclosure(l, servlet_run, 1);
  lua_setfield(l, -2, "run");
  
  result = rb_eval_string_protect("$servlet_run = nil", &status);
  return 1;
}

static int mod_cleanup(lua_State *l)
{
  ruby_cleanup(0);
  return 0;
}

static const luaL_Reg module_rb[] = 
{
  {"init", mod_init},
  {"load_servlet", mod_load_servlet},
  {"cleanup", mod_cleanup},
  {NULL, NULL},
};

LUALIB_API int luaopen_module_rb(lua_State *l)
{
  luaL_newlib(l, module_rb);
  return 1;
}

// https://silverhammermba.github.io/emberb/embed/
// http://silverhammermba.github.io/emberb/c/
// https://silverhammermba.github.io/emberb/examples/
// https://ruby-hacking-guide.github.io/load.html
// https://github.com/andremedeiros/ruby-c-cheat-sheet
// https://fossies.org/linux/www/elinks-0.12pre6.tar.gz/elinks-0.12pre6/src/scripting/ruby/core.c
// "Re: Loading a module without polluting my namespace"
// https://www.ruby-forum.com/topic/211449#918804

// load("hello.rb", true)

#if 0  
  // int state;
  // VALUE result;
  // result = rb_eval_string_protect("puts 'Hello, world!'", &state);
  // path must begin with ./
  VALUE script = rb_str_new_cstr(path);
  int status;
  // the second argument means wrap the loaded code in an anonymous module
  rb_load_protect(script, 1, &status);
  if (status != 0)
  {
    VALUE rbError = rb_funcall(rb_gv_get("$!"), rb_intern("message"), 0);
    return luaL_error(l, "rb_load_protect: %s", StringValuePtr(rbError));
  }
  VALUE servlet = rb_gv_get("$servlet_run");
  // printf("%lu\n", servlet);
  rb_funcall(servlet, rb_intern("call"), 0);
  VALUE result = rb_eval_string_protect("$servlet_run = nil", &status);
  return 0;
#endif
