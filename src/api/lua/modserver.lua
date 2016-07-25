--[[
The servlet API is written in Lua. A C API that calls the Lua API is provided for use by 
languages that can call C. Additional API wrappers are available for other languages.
--]]
local api = {}

local http = require("http")

function api:get_arg(name)
  return self.request.args[name]
end

function api:get_method()
  return self.request.method
end

function api:set_status(status)
  self.status = status
end

function api:set_header(key, value)
  self.headers[key:lower()] = {key = key, value = value}
end

function api:get_header(key)
  return self.request.headers[key:lower()]
end

function api:write_headers()
  local f = self.clientfd_write
  if not self.headers["content-length"] then
    self:set_header("Transfer-Encoding", "chunked")
  end
  local status = self.status or 200
  local status_line 
    = ("HTTP/1.1 %u %s\r\n"):format(status, http.reason_phrase[status] or "")
  f:write(status_line)
  self:set_header("Server", "modserver")
  if not self.headers["content-type"] then
    self:set_header("Content-Type", "text/html; charset=UTF-8")
  end
  self:set_header("Connection", "close")
  for _, pair in pairs(self.headers) do
    f:write(pair.key)
    f:write(": ")
    f:write(pair.value)
    f:write("\r\n")
  end
  f:write("\r\n")
  self.headers_written = true
end

local function write_chunk(f, chunk)
  f:write(("%X\r\n"):format(#chunk))
  f:write(chunk)
  f:write("\r\n")
end

-- FIXME: make sure f:write() does not do a partial write with a really large buffer.
-- if so, see if I can loop on f:write() to output all the data.

function api:rwrite(buffer)
  local f = self.clientfd_write
  if not self.headers_written then
    self:write_headers()
  end
  if self:get_method() == "HEAD" then
    return
  end
  if not self.headers["content-length"] then
    write_chunk(f, buffer)
  else
    f:write(buffer)
  end
end

function api:rflush()
  local f = self.clientfd_write
  f:flush()
end

-- leave MIME parsing of POST body up to the application
function api:read_body(length)
  local content_length = tonumber(self.request.headers["content-length"])
  if not content_length then
    return nil
  end
  local length_left = content_length - self.content_length_read
  if length > length_left then
    length = length_left
  end
  local body_part
  if length_left > 0 then
    self.content_length_read = self.content_length_read + length
    local f = self.clientfd_read
    body_part = f:read(length)
  end
  return body_part
end

return api
