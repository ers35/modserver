--[[
The servlet API is written in Lua. A C API that calls the Lua API is provided for use by 
languages that can call C. Additional API wrappers are available for other languages.
--]]
local api = {}

local http = require("http")

function api:get_arg(name)
  return self.request.query[name]
end

function api:get_method()
  return self.request.method
end

function api:set_status(status)
  self.status = status
end

function api:set_header(name, value)
  self.response_headers[name:lower()] = {name = name, value = value}
end

function api:get_header(name)
  return self.request.headers[name:lower()]
end

function api:write_status_line_and_headers()
  local f = self.clientfd_write
  http.write_status_line(f, self.status or 200)
  self:set_header("Server", "modserver")
  if not self.response_headers["content-length"] then
    self:set_header("Transfer-Encoding", "chunked")
  end
  if not self.response_headers["content-type"] then
    self:set_header("Content-Type", "text/html; charset=UTF-8")
  end
  if not self.response_headers["connection"] then
    self:set_header("Connection", "close")
  end
  http.write_headers(f, self.response_headers)
  f:flush()
  self.response_headers_written = true
end

-- FIXME: make sure f:write() does not do a partial write with a really large buffer.
-- if so, see if I can loop on f:write() to output all the data.

function api:rwrite(buffer)
  local f = self.clientfd_write
  if not self.response_headers_written then
    self:write_status_line_and_headers()
  end
  if self:get_method() == "HEAD" then
    return
  end
  if not self.response_headers["content-length"] then
    http.write_chunk(f, buffer)
  else
    f:write(buffer)
  end
end

function api:rflush()
  local f = self.clientfd_write
  f:flush()
end

return api
