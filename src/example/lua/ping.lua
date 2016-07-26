local servlet = {}

local socket = require("posix.sys.socket")

function servlet:run()
  self:rwrite([[
<!DOCTYPE html>
<html>
<head><title>Ping</title></head>
<body>
<form method="GET">
  Host: <input type="text" name="host" autofocus />
  <input type="submit" value="Ping" />
</form>
<pre>
]])
  local host = self:get_arg("host")
  if host then
    local addr = socket.getaddrinfo(host, nil, {
      family = socket.AF_UNSPEC, socktype = socket.SOCK_STREAM}
    )
    if addr and addr[1] and addr[1].addr then
      local ip = addr[1].addr
      local command = "ping -c 10 " .. ip
      self:rwrite("$ " .. command .. "\n")
      self:rflush()
      for line in io.popen(command):lines() do
        self:rwrite(line .. "\n")
        self:rflush()
      end
    else
      self:rwrite("invalid host")
    end
    self:rwrite([[
</pre>
</body>
</html>
]])
  end
end

return servlet
