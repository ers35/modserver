// C99
#include <assert.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
// Lua
#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>
// Python
#include <Python.h>
// Local
#include "modserver.h"

static PyObject* api_rwrite(PyObject *self, PyObject *args)
{
  PyObject *capsule;
  const char *reply;
  int reply_length;
  if (!PyArg_ParseTuple(args, "Os#", &capsule, &reply, &reply_length))
  {
    PyErr_Print();
  }
  assert(capsule);
  const char *name = PyCapsule_GetName(capsule);
  assert(name);
  servlet *s = PyCapsule_GetPointer(capsule, "servlet*");
  assert(s);
  rwrite(s, reply, reply_length);
  Py_RETURN_NONE;
}

static PyMethodDef api_methods[] = {
  {"rwrite", api_rwrite, METH_VARARGS, "m_doc: rwrite"},
  {NULL, NULL, 0, NULL}
};

static PyModuleDef api_module = {
  PyModuleDef_HEAD_INIT, 
  "modserver", 
  NULL, 
  -1, 
  api_methods,
  NULL, NULL, NULL, NULL
};

static PyObject* PyInit_api(void)
{
  return PyModule_Create(&api_module);
}

static int mod_init(lua_State *l)
{
  PyImport_AppendInittab("modserver", PyInit_api);
  Py_Initialize();
  return 0;
}

static int servlet_run(lua_State *l)
{
  PyObject *run = lua_touserdata(l, lua_upvalueindex(1));
  assert(PyCallable_Check(run));
  PyObject *capsule = PyCapsule_New(l, "servlet*", NULL);
  assert(capsule);
  assert(PyCapsule_GetPointer(capsule, "servlet*"));
  PyObject * ret = PyObject_CallFunction(run, "(O)", capsule);
  if (!ret)
  {
    PyErr_Print();
  }
  return 0;
}

static int mod_load_servlet(lua_State *l)
{
  const char *path = luaL_checkstring(l, -1);
  FILE *f = fopen(path, "r");
  if (!f)
  {
    return luaL_error(l, "servlet not found: %s", path);
  }
  PyObject* main_module = PyImport_AddModule("__main__");
  assert(main_module);
  PyObject* main_dict = PyModule_GetDict(main_module);
  // run each program in a different environment
  // PyDict_Copy appears to be cheap in terms of memory
  PyObject* main_dict_copy = PyDict_Copy(main_dict);
  assert(main_dict);
  (void)PyRun_File(f, path, Py_file_input, main_dict_copy, main_dict_copy);
  fclose(f);
  PyObject *run = PyDict_GetItemString(main_dict_copy, "run");
  if (!run)
  {
    PyErr_Print();
    return 0;
  }
  if (PyCallable_Check(run))
  {
    lua_newtable(l);
    lua_pushlightuserdata(l, run);
    lua_pushcclosure(l, servlet_run, 1);
    lua_setfield(l, -2, "run");
    return 1;
  }
  return 0;
}

static int mod_cleanup(lua_State *l)
{
  Py_Finalize();
  return 0;
}

static const luaL_Reg module_py[] = 
{
  {"init", mod_init},
  {"load_servlet", mod_load_servlet},
  {"cleanup", mod_cleanup},
  {NULL, NULL},
};

LUALIB_API int luaopen_module_py(lua_State *l)
{
  luaL_newlib(l, module_py);
  return 1;
}

// https://docs.python.org/3/extending/embedding.html
// http://stackoverflow.com/questions/36098584/embedded-python-does-not-find-some-modules-ctypes
// http://bugs.python.org/issue26598
// https://github.com/markpasc/luabject/blob/master/src/luabject.cpp
