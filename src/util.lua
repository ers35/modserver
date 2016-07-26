local util = {}

local fcntl = require("posix.fcntl")
local time = require("posix.time")

function util.set_nonblocking(fd)
  local current_flags = fcntl.fcntl(fd, fcntl.F_GETFL)
  fcntl.fcntl(fd, fcntl.F_SETFL, bit32.bor(current_flags, fcntl.O_NONBLOCK))
end

--[[
Make the functions from the cutil C module available in the util module. 
--]]
local cutil = require("cutil")
for k, v in pairs(cutil) do
  util[k] = v
end

function util.test()
  local f = io.tmpfile()
  f:write(("1234567890"):rep(4096))
  f:seek("set")
  local str = util.fgets(128, f)
  print(str, #str)
  f:close()
end
-- util.test()

return util
