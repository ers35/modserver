local http = {}

local errno = require("posix.errno")
local util = require("util")

--[[
Take a query string of the form "?key=value&foo=bar" and return a table 
{key = value, foo = bar}
--]]
local function parse_query_string(query)
  if query then
    local tbl = {}
    for key, value in query:gmatch([[[?&]([%w%.]+)=([%w%.]+)]]) do
      tbl[key] = value
    end
    return tbl
  end
end

--[[

--]]
function http.parse_request_line(line)
  local method, uri = line:match("(%a+)%s+([%w%p]+)%s+")
  return method, uri
end

--[[

--]]
function http.parse_uri(uri)
  local path, query_string = uri:match("^([/%w%a-+%.]+)([?]?.*)")
  return path, query_string
end

--[[
Parse a header of the form Name: Value and return the name and value.
--]]
function http.parse_header(header)
  local name, value = header:match("([%a-]+)%s*:%s*(.+)\r\n")
  return name, value
end

local function errnum_to_status(errnum)
  local status = 400
  if errnum == errno.EAGAIN or errnum == errno.EWOULDBLOCK then
    status = 408
  end
  return nil, http.reason_phrase[status], status
end

--[[
Read the status line and headers from an HTTP request. The body is left unread.
--]]
function http.read_and_parse_request(file)
  local request_line, errmsg, errnum = util.fgets(4096, file)
  if not request_line then
    return errnum_to_status(errnum)
  end
  local method, uri = http.parse_request_line(request_line)
  if not (method and uri) then
    return nil, "Bad Request", 400
  end
  local headers = {}
  local bytes_read = 0
  while true do
    local header, errmsg, errnum = util.fgets(4096, file)
    if not header then
      return errnum_to_status(errnum)
    end
    bytes_read = bytes_read + #header
    if bytes_read > 4096 then
      return nil, "Request Header Fields Too Large", 431
    end
    if header == "\r\n" then
      -- Header parsing is complete.
      break
    end
    local name, value = http.parse_header(header)
    if not (name and value) then
      return nil, "Bad Request", 400
    end
    headers[name:lower()] = value
  end
  local uri_path, query_string = http.parse_uri(uri)
  if not uri_path then
    return nil, "Bad Request", 400
  end
  local request = {
    method = method,
    uri = uri,
    uri_path = uri_path,
    headers = headers,
    query = parse_query_string(query_string),
  }
  return request
end

function http.write_status_line(file, status)
  local status_line 
    = ("HTTP/1.1 %u %s\r\n"):format(status, http.reason_phrase[status] or "")
  file:write(status_line)
end

function http.write_headers(file, headers)
  for _, pair in pairs(headers) do
    file:write(pair.name)
    file:write(": ")
    file:write(pair.value)
    file:write("\r\n")
  end
  file:write("\r\n")
end

function http.write_chunk(file, chunk)
  file:write(("%X\r\n"):format(#chunk))
  file:write(chunk)
  file:write("\r\n")
end

function http.read_chunk(file, length)
  local strhexlength = util.fgets(length, file)
  if not strhexlength then
    return nil
  end
  local chunk_length = tonumber("0x" .. strhexlength)
  if not chunk_length then
    return nil
  end
  if chunk_length == 0 then
    return nil
  end
  local data = util.fgets(chunk_length, file)
  if not data then
    return nil
  end
  if util.fgets(2, file) ~= "\r\n" then
    return nil
  end
  return data
end

-- https://tools.ietf.org/html/rfc2616#section-10
-- http://www.iana.org/assignments/http-status-codes/http-status-codes.xhtml
http.reason_phrase = {
  [100] = "Continue",
  [101] = "Switching Protocols",
  [102] = "Processing",
  [200] = "OK",
  [201] = "Created",
  [202] = "Accepted",
  [203] = "Non-Authoritative Information",
  [204] = "No Content",
  [205] = "Reset Content",
  [206] = "Partial Content",
  [207] = "Multi-Status",
  [208] = "Already Reported",
  [226] = "IM Used",
  [300] = "Multiple Choices",
  [301] = "Moved Permanently",
  [302] = "Found",
  [303] = "See Other",
  [304] = "Not Modified",
  [305] = "Use Proxy",
  [307] = "Temporary Redirect",
  [308] = "Permanent Redirect",
  [400] = "Bad Request",
  [401] = "Unauthorized",
  [402] = "Payment Required",
  [403] = "Forbidden",
  [404] = "Not Found",
  [405] = "Method Not Allowed",
  [406] = "Not Acceptable",
  [407] = "Proxy Authentication Required",
  [408] = "Request Timeout",
  [409] = "Conflict",
  [410] = "Gone",
  [411] = "Length Required",
  [412] = "Precondition Failed",
  [413] = "Payload Too Large",
  [414] = "URI Too Long",
  [415] = "Unsupported Media Type",
  [416] = "Range Not Satisfiable",
  [417] = "Expectation Failed",
  [421] = "Misdirected Request",
  [422] = "Unprocessable Entity",
  [423] = "Locked",
  [424] = "Failed Dependency",
  [426] = "Upgrade Required",
  [428] = "Precondition Required",
  [429] = "Too Many Requests",
  [431] = "Request Header Fields Too Large",
  [451] = "Unavailable For Legal Reasons",
  [500] = "Internal Server Error",
  [501] = "Not Implemented",
  [502] = "Bad Gateway",
  [503] = "Service Unavailable",
  [504] = "Gateway Timeout",
  [505] = "HTTP Version Not Supported",
  [506] = "Variant Also Negotiates",
  [507] = "Insufficient Storage",
  [508] = "Loop Detected",
  [510] = "Not Extended",
  [511] = "Network Authentication Required",
}

function http.test()
  local inspect = require("inspect")
  local function req(tbl)
    local file = io.tmpfile()
    local request = table.concat(tbl, "\r\n")
    file:write(request)
    file:seek("set")
    local parsed_request = http.read_and_parse_request(file)
    print(inspect(parsed_request), "\n")
    file:close()
    return parsed_request
  end
  
  assert(req{
  "GET / HTTP/1.1",
  "Host: www.example.com",
  "User-Agent: foo",
  "\r\n",
  })
  
  assert(req{
  "GET /?foo=bar&abc=123 HTTP/1.1",
  -- the client tries to send infinitely long lines
  "foo: " .. (" "):rep(9999999) .. "bar",
  "Host: www.example.com",
  "User-Agent: foo",
  "\r\n",
  } == nil)
end
-- http.test()

return http
