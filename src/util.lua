local util = {}

local cutil = require("cutil")
local errno = require("posix.errno")
local fcntl = require("posix.fcntl")

function util.set_nonblocking(fd)
  local current_flags = fcntl.fcntl(fd, fcntl.F_GETFL)
  fcntl.fcntl(fd, fcntl.F_SETFL, bit32.bor(current_flags, fcntl.O_NONBLOCK))
end

function util.fgets(length, file)
  while true do
    local buffer, errmsg, errnum = cutil.fgets(4096, file)
    if errnum ~= errno.EINTR then
      return buffer, errmsg, errnum
    end
  end
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
