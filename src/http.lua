local http = {}

local errno = require("posix.errno")
local lpeg = require("lpeg")
lpeg.locale(lpeg)
local util = require("util")

--[[
Generate an HTTP parser with LPeg. The code below resembles the BNF in the RFC. See 
http://www.inf.puc-rio.br/~roberto/lpeg/ for the LPeg documentation.
--]]
local parse = {}
do
  local SP = lpeg.space ^ 0
  local CTL = lpeg.cntrl
  local HR = lpeg.P(string.char(9))
  local CLRF = lpeg.P("\r\n")
  local method =
  (
    lpeg.C("OPTIONS") + 
    lpeg.C("GET") + 
    lpeg.C("HEAD") + 
    lpeg.C("POST") + 
    lpeg.C("PUT") + 
    lpeg.C("DELETE") + 
    lpeg.C("TRACE") + 
    lpeg.C("CONNECT")
  )
  local request_uri = lpeg.C(lpeg.P("/") * ((lpeg.alnum + lpeg.punct) ^ 0))
  local HTTP_version = 
    lpeg.C(  lpeg.P("HTTP/") * (lpeg.digit ^ 1) * lpeg.P(".") * (lpeg.digit ^ 1)  )
  local request_line = method * SP * request_uri * SP * HTTP_version * CLRF
  local separators = lpeg.S([[=()<>@,;:\<>/[]?={}]])
  -- "If patt is a character set, 1 - patt is its complement."
  local token = lpeg.C(  (1 - (separators + CTL + " " + HR)) ^ 1  )
  local field_name = token / string.lower
  local field_value = lpeg.C(  (lpeg.alnum + lpeg.punct + lpeg.S(" ")) ^ 0  )
  local header_field = lpeg.Cg(  field_name * SP * ":" * SP * field_value  ) * CLRF ^ -1
  local entity_header = lpeg.Cf(lpeg.Ct("") * header_field ^ 0, rawset)
  local request = request_line * entity_header * CLRF
  
  parse = {
    request_line = request_line,
    header_field = header_field,
    request = request,
  }
end

--[[

--]]
function http.parse_request_line(line)
  local method, uri, version = parse.request_line:match(line)
  return method, uri, version
end

--[[

--]]
function http.parse_response_line(line)
  local status, reason = line:match("%s+(%d+)%s+([%a%s]+)\r\n")
  return tonumber(status), reason
end

--[[

--]]
function http.parse_uri(uri)
  local path, query_string = uri:match("^([/%w%a-+%.]+)([?]?.*)")
  return path, query_string
end

--[[
Take a query string of the form "?key=value&foo=bar" and return a table 
{key = value, foo = bar}
--]]
function http.parse_query_string(query)
  local tbl = {}
  for key, value in query:gmatch([[[?&]([%w%.]+)=?([%w%.]*)]]) do
    tbl[key] = value
  end
  return tbl
end

--[[
Parse a header of the form Name: Value and return the name and value.
--]]
function http.parse_header(header)
  local name, value = parse.header_field:match(header)
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
    if errmsg == "EOF" then
      return nil, nil, nil
    else
      return errnum_to_status(errnum)
    end
  end
  local method, uri, version = http.parse_request_line(request_line)
  if not (method and uri and version) then
    return nil, "Bad Request", 400
  end
  local headers = {}
  local bytes_read = 0
  while true do
    local header, errmsg, errnum = util.fgets(4096, file)
    if not header then
      if errmsg == "EOF" then
        return nil, nil, nil
      else
        return errnum_to_status(errnum)
      end
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
    query = http.parse_query_string(query_string or ""),
  }
  return request
end

function http.write_status_line(file, status)
  local status_line 
    = ("HTTP/1.1 %u %s\r\n"):format(status, http.reason_phrase[status] or "")
  assert(file:write(status_line))
end

function http.write_headers(file, headers)
  for _, pair in pairs(headers) do
    assert(file:write(pair.name, ": ", pair.value, "\r\n"))
  end
end

function http.write_chunk(file, chunk)
  if assert(file:write(("%X\r\n"):format(#chunk), chunk, "\r\n")) then
    return #chunk
  end
end

--[[
https://tools.ietf.org/html/rfc2616#section-10
http://www.iana.org/assignments/http-status-codes/http-status-codes.xhtml
--]]
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

-- Tests below this line:
------------------------------------------------------------------------------------------

if os.getenv("TEST") == "1" then
  if true then
    local method, uri, version = http.parse_request_line("GET / HTTP/1.1\r\n")
    assert(method == "GET")
    assert(uri == "/")
    assert(version == "HTTP/1.1")
    method, uri, version = http.parse_request_line("GET / HTTP/1.0\r\n")
    assert(method == "GET")
    assert(uri == "/")
    assert(version == "HTTP/1.0")
    method, uri, version = http.parse_request_line("GET / HTTP/12.21\r\n")
    assert(method == "GET")
    assert(uri == "/")
    assert(version == "HTTP/12.21")
    method, uri, version = http.parse_request_line("GET    /    HTTP/1.1\r\n")
    assert(method == "GET")
    assert(uri == "/")
    assert(version == "HTTP/1.1")
    method, uri, version = http.parse_request_line("GET /foo HTTP/1.1\r\n")
    assert(method == "GET")
    assert(uri == "/foo")
    assert(version == "HTTP/1.1")
    method, uri, version = http.parse_request_line("GET /foo?key HTTP/1.1\r\n")
    assert(method == "GET")
    assert(uri == "/foo?key")
    assert(version == "HTTP/1.1")
    method, uri, version = http.parse_request_line("GET /foo?key HTTP/.\r\n")
    assert(method == nil and uri == nil and version == nil)
  end
  
  if true then
    local status, reason = http.parse_response_line("HTTP/1.1 200 OK\r\n")
    assert(status == 200)
    assert(reason == "OK")
    status, reason = http.parse_response_line("HTTP/1.1    200      OK\r\n")
    assert(status == 200)
    assert(reason == "OK")
    status, reason = http.parse_response_line("HTTP/1.1 404 Not Found\r\n")
    assert(status == 404)
    assert(reason == "Not Found")
  end
  
  if true then
    local uri_path, query_string = http.parse_uri("/")
    assert(uri_path == "/")
    assert(query_string == "")
    uri_path, query_string = http.parse_uri("/?key")
    assert(uri_path == "/")
    assert(query_string == "?key")
    uri_path, query_string = http.parse_uri("/foo?key=value")
    assert(uri_path == "/foo")
    assert(query_string == "?key=value")
  end
  
  do
    local query = http.parse_query_string([[?key=value&foo=bar]])
    assert(query["key"] == "value")
    assert(query["foo"] == "bar")
    query = http.parse_query_string([[?key]])
    assert(query["key"])
    query = http.parse_query_string([[?key&foo]])
    assert(query["key"])
    assert(query["foo"])
    query = http.parse_query_string([[?key=value&foo=bar]])
    assert(query["key"] == "value")
    assert(query["foo"] == "bar")
  end
  
  if true then
    local name, value = http.parse_header("Name: Value\r\n")
    assert(name == "name")
    assert(value == "Value")
    name, value = http.parse_header("Name:       Value\r\n")
    assert(name == "name")
    assert(value == "Value")
    name, value = http.parse_header("Name :Value\r\n")
    assert(name == "name")
    assert(value == "Value")
    name, value = http.parse_header("Name      :Value\r\n")
    assert(name == "name")
    assert(value == "Value")
    name, value = http.parse_header("Name     :      Value\r\n")
    assert(name == "name")
    assert(value == "Value")
    name, value = http.parse_header([[Space-in-Value     :     "[  -  ]"]])
    assert(name == "space-in-value")
    assert(value == [["[  -  ]"]])
  end
  
  do
    local _, errstr, errnum = errnum_to_status(errno.EAGAIN)
    assert(errnum == 408)
    assert(errstr == http.reason_phrase[errnum])
    
    local _, errstr, errnum = errnum_to_status(errno.EINTR)
    assert(errnum == 400)
    assert(errstr == http.reason_phrase[errnum])
  end
  
  do
    local function request(tbl)
      local file = io.tmpfile()
      local request = table.concat(tbl, "\r\n")
      assert(file:write(request))
      assert(file:seek("set"))
      local parsed_request, errstr, errnum = http.read_and_parse_request(file)
      -- local inspect = require("inspect"); print(inspect(parsed_request), "\n")
      file:close()
      return parsed_request, errstr, errnum
    end
    
    local pr, errstr, errnum = request{
      "GET /foo?key=value HTTP/1.1",
      "Host: www.example.com",
      "User-Agent: foo",
      "\r\n"
    }
    assert(pr.method == "GET")
    assert(pr.uri == "/foo?key=value")
    assert(pr.uri_path == "/foo")
    assert(pr.query["key"] == "value")
    assert(pr.headers["host"] == "www.example.com")
    assert(pr.headers["user-agent"] == "foo")
    
    pr, errstr, errnum = request{
      "GET    /            HTTP/1.1",
      "Host: www.example.com",
      "User-Agent: foo",
      "\r\n",
    }
    assert(pr.method == "GET")
    assert(pr.uri == "/")
    
    pr, errstr, errnum = request{
    }
    assert(pr == nil)
    assert(errstr == nil)
    assert(errnum == nil)
  end
  
  do
    local file = io.tmpfile()
    http.write_status_line(file, 200)
    assert(file:seek("set"))
    assert(file:read("*all") == "HTTP/1.1 200 OK\r\n")
    file:close()
  end
  
  if true then
    local file = io.tmpfile()
    local headers = {
      ["name"] = {name = "Name", value = "Value"},
      ["foo"] = {name = "Foo", value = "Bar"},
    }
    http.write_headers(file, headers)
    assert(file:seek("set"))
    for header in file:lines("*L") do
      local name, value = http.parse_header(header)
      local pair = headers[name:lower()]
      assert(pair.name:lower() == name)
      assert(pair.value == value)
    end
    file:close()
  end
  
  do
    local file = io.tmpfile()
    local buffer = "hello world"
    http.write_chunk(file, buffer)
    assert(file:seek("set"))
    local chunk = file:read("*all")
    assert(chunk == "B\r\n" .. buffer .. "\r\n")
    file:close()
    
    file = io.tmpfile()
    buffer = ""
    http.write_chunk(file, buffer)
    assert(file:seek("set"))
    chunk = file:read("*all")
    assert(chunk == "0\r\n\r\n")
    file:close()
  end
  
  do
    assert(http.reason_phrase[200] == "OK")
    assert(http.reason_phrase[404] == "Not Found")
  end
  
  print("http.lua test complete")
end

return http

--[[
https://tools.ietf.org/html/rfc2396
https://tools.ietf.org/html/rfc2616
https://tools.ietf.org/html/rfc7230
--]]
