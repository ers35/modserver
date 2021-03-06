--[[
The configuration file is written in Lua. Functions called in the config file set 
configurable parameters. Users should not have to be Lua programmers to change the 
configuration file. The user may not even realize the syntax is Lua. This is why the 
example filename is config.conf and not config.lua.
--]]

local socket = require("posix.sys.socket")
local grp = require("posix.grp")
local pwd = require("posix.pwd")
local stat = require("posix.sys.stat")
local unistd = require("posix.unistd")
local util = require("util")

local config = {
  cfg = {
    reload = false,
    poll_timeout = 1000,
  },
  modules = {},
  servlets = {},
  routes = {},
  listenfds = {},
}

--[[
The config file is run with the config table as its environment. Only functions in the 
config table can be called.

--Example:
load_config "config.conf"
--]]
function config.load_config(path)
  local func = assert(loadfile(path, "t", config))
  assert(pcall(func))
end

--[[
Set the address and port on which the server accepts requests.

listen may be used multiple times to listen on multiple addresses.

--Example:
-- IPv4
listen "0.0.0.0:8080"
-- IPv6
listen "::1:8080"
--]]
function config.listen(str)
  local address, port = str:match([[(.+):(%d+)]])
  port = assert(tonumber(port), "the listen port must be a number")
  local addrinfo = assert(socket.getaddrinfo(address, port, {
    family = socket.AF_UNSPEC, socktype = socket.SOCK_STREAM}
  ))
  local fd = assert(socket.socket(addrinfo[1].family, socket.SOCK_STREAM, 0))
  util.set_close_on_exec(fd)
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
Set the user and group under which the server runs. If the group is not specified, the 
user name is used as the group name.

--Example:
user "www-data"
user ("www-data", "www-data")
--]]
function config.user(user, group)
  local user_struct = assert(pwd.getpwnam(user), "user not found")
  local group_struct = assert(grp.getgrnam(group or user), "group not found")
  local uid = user_struct.pw_uid
  local gid = group_struct.gr_gid
  -- Always set the group before the user:
  -- https://www.securecoding.cert.org/confluence/x/dgL7
  assert(unistd.setpid("g", gid))
  assert(unistd.setpid("u", uid))
end

--[[
Modules add support for calling foreign functions of servlets. Each module defines a 
load_servlet() function that know how to load a particular type of servlet.

Modules follow the format used by Lua's require() function:
http://www.lua.org/manual/5.2/manual.html#6.3

--Example:
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
    for _, extension in ipairs(extensions) do
      config.modules[extension] = mod
    end
    print([[load_module "]] .. path .. [["]])
  else
    -- Print the error.
    print(tostring(mod))
  end
end

--[[
Load the servlet from the specified path. The default route is the same as the path. The 
second argument optionally set the route.

The file extension determines which module is used to load the servlet.

Servlets dynamically generate responses to requests using the provided API. Servlets can 
define three functions:
  init() is called the first time the servlet is requested and is optional.
  run() is called each time the servlet is requested and must be defined.
  cleanup() is called before the process containing the servlet exits and is optional.
  
--Example:
load_servlet "example/lua/servlet.lua"
load_servlet ("index.lua", "/")
--]]
function config.load_servlet(path, route)
  route = route or "/" .. path
  local extension = path:match("%.(%a+)$")
  local mod = config.modules[extension]
  if mod then
    local ok, servlet = pcall(mod.load_servlet, path)
    if ok and servlet then
      config.routes[route] = servlet
      -- print("loaded servlet:", path)
    else
      print("failed to load servlet:", servlet)
      servlet = {}
    end
    servlet.initialized = false
    servlet.path = path
    local stat_tbl = stat.stat(servlet.path)
    if stat_tbl then
      servlet.file_modified_time = stat_tbl.st_mtime
    else
      servlet.file_modified_time = 0
    end
    config.servlets[path] = servlet
  else
    print("no module can handle extension:", extension)
  end
end

--[[
Automatically reload the server when a servlet is modified. This is useful for 
development.

--Example:
reload "on"
--]]
function config.reload(str)
  if str == "on" then
    config.cfg.reload = true
    config.cfg.poll_timeout = 100
  else
    config.cfg.reload = false
    config.cfg.poll_timeout = 1000
  end
end

return config
