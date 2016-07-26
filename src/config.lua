--[[
The configuration file is written in Lua. Functions called in the config file set 
configurable parameters. Users should not have to be Lua programmers to change the 
configuration file. The user may not even realize the syntax is Lua. This is why the 
example filename is config.conf and not config.lua.
--]]

local socket = require("posix.sys.socket")

-- Set default configuration parameters.
local config = {
  modules = {},
  servlets = {},
  routes = {},
  listenfds = {},
}

--[[
The config file is run with the config table as its environment. Only functions in the 
config table can be called.
--]]
function config.load_config(path)
  local func = assert(loadfile(path, "t", config))
  assert(pcall(func))
end

-- The TCP port on which the server listens.
function config.listen(str)
  local address, port = str:match([[(.+):(%d+)]])
  port = assert(tonumber(port), "the listen port must be a number")
  local addrinfo = assert(socket.getaddrinfo(address, port, {
    family = socket.AF_UNSPEC, socktype = socket.SOCK_STREAM}
  ))
  local fd = assert(socket.socket(addrinfo[1].family, socket.SOCK_STREAM, 0))
  assert(socket.setsockopt(fd, socket.SOL_SOCKET, socket.SO_REUSEADDR, 1))
  assert(socket.bind(
    fd, {family = addrinfo[1].family, addr = addrinfo[1].addr, port = port}
  ), "unable to listen on port: " .. port)
  assert(socket.listen(fd, 1024))
  -- The children socket inherits this option on a fork.
  assert(socket.setsockopt(fd, socket.SOL_SOCKET, socket.SO_RCVTIMEO, 5, 0))
  table.insert(config.listenfds, fd)
end

--[[
Modules add support for calling foreign functions of servlets. Each module defines a 
load_servlet() function that know how to load a particular type of servlet.

Modules follow the format used by Lua's require() function:
http://www.lua.org/manual/5.2/manual.html#6.3

Example:
load_module ("module.lua", "lua")
load_module ("module.lua", {"lua", "luac"})
--]]
function config.load_module(path, extensions)
  assert(extensions, "load_module must have a second argument")
  if type(extensions) == "string" then
    extensions = {extensions}
  end
  local ok, mod = pcall(require, path)
  if ok and mod then
    assert(type(mod) == "table", "error loading module: " .. path)
    if mod.init then
      mod.init()
    end
    assert(mod.load_servlet, "this module needs a load_servlet() function: " .. path)
    for i, extension in ipairs(extensions) do
      config.modules[extension] = mod
    end
    print([[load_module "]] .. path .. [["]])
  else
    -- Print the error.
    print(tostring(mod))
  end
end

--[[
Servlets dynamically generate responses to requests using the provided API. Servlets can 
define three functions:
  init() is called the first time the servlet is requested and is optional.
  run() is called each time the servlet is requested and must be defined.
  cleanup() is called before the process containing the servlet exits and is optional.
  
Example:
load_servlet "example/lua/servlet.lua"
--]]
function config.load_servlet(path, route)
  route = route or "/" .. path
  local extension = path:match("%.(%a+)$")
  local mod = config.modules[extension]
  if mod then
    local ok, servlet = pcall(mod.load_servlet, path)
    if ok and servlet then
      servlet.num_run = 0
      config.servlets[path] = servlet
      config.routes[route] = servlet
      -- print("loaded servlet:", path)
    else
      print("failed to load servlet:", servlet)
    end
  else
    print("no module can handle extension:", extension)
  end
end

return config
