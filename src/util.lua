local util = {}

local time = require("posix.time")

function util.time_ns()
  local ts = time.clock_gettime(time.CLOCK_MONOTONIC)
  return tonumber((ts.tv_sec * 1000000000) + ts.tv_nsec)
end

function util.seconds(seconds)
  return seconds * 1000000000
end

util.timestamp = 0

function util.ts()
  util.timestamp = util.time_ns()
  return util.timestamp
end

function util.te()
  local now = util.time_ns()
  print(now - util.timestamp)
  return now
end

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
