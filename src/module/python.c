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
#define PY_SSIZE_T_CLEAN
#include <Python.h>
// Local
#include "modserver.h"

static void pyassert(int success)
{
  if (!success)
  {
    PyErr_Print();
  }
}

static servlet* get_servlet(PyObject *capsule)
{
  assert(capsule);
  const char *name = PyCapsule_GetName(capsule);
  assert(name);
  servlet *s = PyCapsule_GetPointer(capsule, "servlet*");
  assert(s);
  return s;
}

static PyObject* api_get_arg(PyObject *self, PyObject *args)
{
  PyObject *capsule;
  const char *name;
  pyassert(PyArg_ParseTuple(args, "Os", &capsule, &name));
  servlet *s = get_servlet(capsule);
  const char *value = get_arg(s, name);
  PyObject *value_obj = Py_BuildValue("s", value);
  return value_obj;
}

static PyObject* api_get_method(PyObject *self, PyObject *args)
{
  PyObject *capsule;
  pyassert(PyArg_ParseTuple(args, "O", &capsule));
  servlet *s = get_servlet(capsule);
  const char *method = get_method(s);
  PyObject *method_obj = Py_BuildValue("s", method);
  return method_obj;
}

static PyObject* api_get_header(PyObject *self, PyObject *args)
{
  PyObject *capsule;
  const char *key;
  pyassert(PyArg_ParseTuple(args, "Os", &capsule, &key));
  servlet *s = get_servlet(capsule);
  const char *value = get_header(s, key);
  PyObject *value_obj = Py_BuildValue("s", value);
  return value_obj;
}

static PyObject* api_set_status(PyObject *self, PyObject *args)
{
  PyObject *capsule;
  int status;
  pyassert(PyArg_ParseTuple(args, "Oi", &capsule, &status));
  servlet *s = get_servlet(capsule);
  set_status(s, status);
  Py_RETURN_NONE;
}

static PyObject* api_set_header(PyObject *self, PyObject *args)
{
  PyObject *capsule;
  const char *key;
  const char *value;
  pyassert(PyArg_ParseTuple(args, "Oss", &capsule, &key, &value));
  servlet *s = get_servlet(capsule);
  set_header(s, key, value);
  Py_RETURN_NONE;
}

static PyObject* api_rwrite(PyObject *self, PyObject *args)
{
  PyObject *capsule;
  const char *reply;
  ssize_t length;
  pyassert(PyArg_ParseTuple(args, "Os#", &capsule, &reply, &length));
  if (length > 0)
  {
    servlet *s = get_servlet(capsule);
    size_t ret = rwrite(s, reply, length);
    PyObject *ret_obj = Py_BuildValue("#", (size_t)ret);
    return ret_obj;
  }
  Py_RETURN_NONE;
}

static PyObject* api_rflush(PyObject *self, PyObject *args)
{
  PyObject *capsule;
  pyassert(PyArg_ParseTuple(args, "O", &capsule));
  servlet *s = get_servlet(capsule);
  rflush(s);
  Py_RETURN_NONE;
}

static PyMethodDef api_methods[] = {
  {"get_arg", api_get_arg, METH_VARARGS, "m_doc: get_arg"},
  {"get_method", api_get_method, METH_VARARGS, "m_doc: get_method"},
  {"get_header", api_get_header, METH_VARARGS, "m_doc: get_header"},
  {"set_status", api_set_status, METH_VARARGS, "m_doc: set_status"},
  {"set_header", api_set_header, METH_VARARGS, "m_doc: set_header"},
  {"rwrite", api_rwrite, METH_VARARGS, "m_doc: rwrite"},
  {"rflush", api_rflush, METH_VARARGS, "m_doc: rflush"},
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

static const luaL_Reg module_python[] = 
{
  {"init", mod_init},
  {"load_servlet", mod_load_servlet},
  {"cleanup", mod_cleanup},
  {NULL, NULL},
};

LUALIB_API int luaopen_module_python(lua_State *l)
{
  luaL_newlib(l, module_python);
  return 1;
}

// https://docs.python.org/3/extending/embedding.html
// http://stackoverflow.com/questions/36098584/embedded-python-does-not-find-some-modules-ctypes
// http://bugs.python.org/issue26598
// https://github.com/markpasc/luabject/blob/master/src/luabject.cpp
