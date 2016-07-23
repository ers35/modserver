local http = {}

local util = require("util")

--[[
Take a string of URI arguments in the form "?key=value&foo=bar" and return a table 
{key = value, foo = bar}
--]]
local function parse_args(args)
  if args then
    local tbl = {}
    for key, value in args:gmatch[[[?&]([%w%.]+)=([%w%.]+)]] do
      tbl[key] = value
    end
    return tbl
  end
end

function http.read_and_parse_request_from_file(f)
  local request
  local bytes_read = 0
  local request_line = util.fgets(4096, f)
  if not request_line or request_line == 0 then
    return nil
  end
  bytes_read = bytes_read + #request_line
  local method, uri = request_line:match("(%a+)%s+([%w%p]+)%s+")
  if method and uri then
    local headers = {}
    while true do
      local header = util.fgets(4096, f)
      if not header then
        return nil
      end
      bytes_read = bytes_read + #header
      if header == "\r\n" then
        break
      end
      local key, value = header:match("([%a-]+)%s*:%s*(.+)\r\n")
      if not key or not value then
        return nil
      end
      headers[key:lower()] = value
      if bytes_read > 4096 then
        break
      end
    end
    request = {
      method = method,
      uri = uri,
      headers = headers,
    }
    local uri_path, args = request.uri:match("^([/%w%a-+%.]+)([?]?.*)")
    request.uri_path = uri_path
    request.args = parse_args(args)
  end
  return request
end

function http.test()
  local inspect = require("inspect")
  local function req(tbl)
    local f = io.tmpfile()
    local request = table.concat(tbl, "\r\n")
    f:write(request)
    f:seek("set")
    local parsed_request = http.read_and_parse_request_from_file(f)
    print(inspect(parsed_request), "\n")
    f:close()
  end
  
  req{
  "GET / HTTP/1.1",
  "Host: www.example.com",
  "User-Agent: foo",
  "\r\n",
  }
  
  req{
  "GET /?foo=bar&abc=123 HTTP/1.1",
  -- the client tries to send infinitely long lines
  "foo: " .. (" "):rep(9999999) .. "bar",
  "Host: www.example.com",
  "User-Agent: foo",
  "\r\n",
  }
end
-- http.test()

return http
