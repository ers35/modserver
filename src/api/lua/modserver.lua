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
  local file = self.clientfd_write
  http.write_status_line(file, self.status or 200)
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
  http.write_headers(file, self.response_headers)
  assert(file:write("\r\n"))
  self.response_headers_written = true
end

local function api_rwrite(self, buffer)
  local file = self.clientfd_write
  if not self.response_headers_written then
    self:write_status_line_and_headers()
  end
  if self:get_method() == "HEAD" then
    return #buffer
  end
  if not self.response_headers["content-length"] then
    return http.write_chunk(file, buffer)
  else
    if assert(file:write(buffer)) then
      return #buffer
    end
  end
end

function api:rwrite(buffer)
  local ok, ret, errstr, errnum = pcall(api_rwrite, self, buffer)
  if ok then
    return #buffer
  end
  return ret, errstr, errnum
end

function api:rflush()
  local file = self.clientfd_write
  file:flush()
end

return api
