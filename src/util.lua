local util = {}

local cutil = require("cutil")
local errno = require("posix.errno")
local fcntl = require("posix.fcntl")
local signal = require("posix.signal")

function util.set_nonblocking(fd)
  local current_flags = fcntl.fcntl(fd, fcntl.F_GETFL)
  fcntl.fcntl(fd, fcntl.F_SETFL, bit32.bor(current_flags, fcntl.O_NONBLOCK))
end

function util.fgets(length, file)
  while true do
    local buffer, errmsg, errnum = cutil.fgets(length, file)
    if errnum ~= errno.EINTR then
      return buffer, errmsg, errnum
    end
  end
end

--[[
A process may only set one signal handler per signal type. Certain language 
implementations set signal handlers. This poses a problem because the handlers conflict 
with each other. Assume that the signal handlers are only used for debugging crashes and 
set them all to SIG_DFL to have the parent process report the crash instead. 
Unfortunately, useful debugging information like stack traces are lost. Perhaps creating 
a core dump when a servlet crashes is a reasonable compromise.
--]]
function util.set_default_signal_handlers()
  for _, signal_name in ipairs{
    "SIGINT",
    "SIGSEGV",
    "SIGABRT",
    "SIGFPE",
    "SIGILL",
    "SIGBUS",
    "SIGCHLD",
  } do
    signal.signal(signal[signal_name], signal.SIG_DFL)
  end
  -- Prefer handling SIGPIPE at each write call instead of terminating the process.
  signal.signal(signal.SIGPIPE, signal.SIG_IGN)
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
