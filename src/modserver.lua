-- The author disclaims copyright to this source code.

local api = require("api.lua.modserver")
local config = require("config")
local http = require("http")
local util = require("util")
--[[
luaposix provides access to the POSIX standards for functionality Lua lacks such as 
networking. See https://github.com/luaposix/luaposix for more details.
]]
local errno = require("posix.errno")
local signal = require("posix.signal")
local socket = require("posix.sys.socket")
local stdio = require("posix.stdio")
local poll = require("posix.poll")
local unistd = require("posix.unistd")
local wait = require("posix.sys.wait")

-- A configuration file is required to start the server.
if #arg < 1 then
  local version = "0.0.1"
  print("modserver " .. version)
  print("usage: modserver config.conf")
  os.exit()
else
  config.load_config(arg[1])
  if #config.listenfds == 0 then
    error("The server is not listening on any ports. Check the config file.")
  end
end

local main = {}

--[[
Children use these functions to communicate their state to the parent over a pipe.

A child process can be in one of two states:
  (+) Waiting on accept() to handle a request.
  (-) Busy handling a request or otherwise not ready.
--]]
function main.child_is_ready(wpipe, padded_pid)
  unistd.write(wpipe, padded_pid .. "+")
end
function main.child_is_busy(wpipe, padded_pid)
  unistd.write(wpipe, padded_pid .. "-")
end

--[[
A process may only set one signal handler per signal type. Certain language 
implementations set signal handlers. This poses a problem because the handlers conflict 
with each other. Assume that the signal handlers are only used for debugging crashes and 
set them all to SIG_DFL to have the parent process report the crash instead. 
Unfortunately, useful debugging information like stack traces are lost. Perhaps creating 
a core dump when a servlet crashes is a reasonable compromise.
--]]
local function set_default_signal_handlers()
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

--[[
The role of the parent process is to manage the number of child processes.
--]]
function main.parent_loop()
  -- The parent and children communicate over a pipe.
  local rpipe, wpipe = unistd.pipe()

  set_default_signal_handlers()
  
  -- Terminate the server when Ctrl+C is pressed.
  signal.signal(signal.SIGINT, function()
    signal.kill(0, signal.SIGKILL)
    while (wait.wait()) do
      -- Wait for children to exit.
    end
  end)

  local poll_fds = {
    [rpipe] = {events = {IN = true}},
  }
  util.set_nonblocking(rpipe)

  -- Keep track of forked child processes by their pid.
  local children = {}
  local num_children = 0
  local num_children_ready = 0
  while true do
    --[[
    The parent process forks a child process when there are no ready child processes. A 
    ready child process is one that is waiting to accept a client connection. 
    --]]
    assert(num_children_ready >= 0, "negative num_children_ready")
    if num_children_ready == 0 then
      local childpid = assert(unistd.fork())
      if childpid == 0 then
        -- a new child process
        unistd.close(rpipe)
        main.child_loop(wpipe, config.listenfds, num_children > 0)
        error("returned from child_loop()")
      elseif childpid > 0 then
        -- the same parent process
        children[childpid] = {state = "f"}
        num_children = num_children + 1
      end
    end
    
    --[[
    Wait up to one second for messages from children.
    --]]
    local ret = poll.poll(poll_fds, 1000)
    if ret > 0 then
      for fd in pairs(poll_fds) do
        if poll_fds[fd].revents.IN then
          repeat
            -- The parent waits on one pipe for messages from many children.
            local data, errmsg, errnum = unistd.read(rpipe, 21 * 128)
            if data then
              -- The message uses this text format:
              -- [20 byte padded string pid][1 byte command]
              -- 00000000000000018838+
              -- The message is always 21 bytes in size.
              for strpid, cmd in data:gmatch("(%d+)([-+])") do
                local numpid = tonumber(strpid)
                local child = children[numpid]
                if child then
                  if cmd == "+" then
                    num_children_ready = num_children_ready + 1
                  elseif cmd == "-" then
                    assert(child.state == "+")
                    num_children_ready = num_children_ready - 1
                  else
                    print(data)
                    error("bad cmd")
                  end
                  child.state = cmd
                end
              end
            end
          until errnum ~= errno.EINTR
        end
      end
    end
    
    --[[
    Wait for state changes in the child processes, if any. Report the pid of any crashes.
    --]]
    repeat
      local pid, status, code = wait.wait(-1, wait.WNOHANG)
      if pid and pid ~= 0 then
        local child = children[pid]
        if child and child.state == "+" then
          num_children_ready = num_children_ready - 1
        end
        children[pid] = nil
        num_children = num_children - 1
        assert(num_children >= 0, "negative num_children")
        if code ~= 0 then
          print(pid, status, code)
        end
      end
    until not pid or pid == 0 or pid == -1
  end
end

--[[
Read the request, choose the servlet to handle the request, run the servlet, and close 
the connection.
--]]
function main.handle_request(readf, writef)
  local state = {
    request = {method = "", headers = {}, query = {}},
    clientfd_read = readf,
    clientfd_write = writef,
    response_headers_written = false,
    response_headers = {},
  }
  setmetatable(state, {__index = api})
  local request, errmsg, errnum = http.read_and_parse_request(state.clientfd_read)
  if request then
    state.request = request
    local servlet = config.routes[request.uri_path]
    if servlet then
      --[[
      8.2.3 Use of the 100 (Continue) Status
      https://tools.ietf.org/html/rfc2616#section-8.2.3
      --]]
      if state.request.headers["expect"] == "100-continue" then
        assert(state.clientfd_write:write("HTTP/1.1 100 Continue\r\n\r\n"))
        -- flush() because the user expects prompt notification of the status.
        assert(state.clientfd_write:flush())
      end
      if not servlet.initialized then
        if servlet.init then
          servlet.init(state)
          -- Override languages that set their own signal handlers.
          set_default_signal_handlers()
          servlet.initialized = true
        end
      end
      servlet.run(state)
    else
      -- No servlet can handle the request.
      state:set_status(404)
      state:rwrite("404 Not Found")
    end
  else
    if errnum then
      state:set_status(errnum)
      state:rwrite(("%u %s"):format(errnum, errmsg))
    else
      return
    end
  end
  if not state.response_headers_written then
    --[[
    The servlet did not write any data.
    --]]
    state:set_status(204)
    state:set_header("Content-Length", "0")
    state:write_status_line_and_headers()
  end
  if not state.response_headers["content-length"] then
    -- Send the last chunk of the chunked response.
    assert(state.clientfd_write:write("0\r\n\r\n"))
  end
  --[[
  flush() does not need to be called because the stream is automatically flushed when the 
  connection is closed. However, keep this reminder here because flush() must be used if 
  persistent keep-alive connections are implemented.
  --]]
  -- assert(state.clientfd_write:flush())
end

--[[
Each child process waits to accept one connection on the same server socket. The kernel 
load balances the connections across all child processes. The child tells the parent of 
two events: before the child waits on accept and after the child accepts a connection. 
The parent uses these events to keep track of how many child are ready to handle new 
connections.
--]]
function main.child_loop(wpipe, listenfds, exit_on_timeout)
  local mypid = unistd.getpid()
  local padded_pid = ("%020u"):format(mypid)
  main.child_is_ready(wpipe, padded_pid)
  local poll_fds = {}
  for i, fd in ipairs(listenfds) do
    poll_fds[fd] = {events = {IN = true}}
  end
  while true do
    local ret, errmsg, errnum = poll.poll(poll_fds, 5000)
    if ret then
      if ret > 0 then
        for fd in pairs(poll_fds) do
          if poll_fds[fd].revents.IN then
            local clientfd, _, _ = socket.accept(fd)
            if clientfd then
              main.child_is_busy(wpipe, padded_pid)
              --[[
              A read from the socket returns with an error after five seconds of 
              inactivity rather than blocking forever.
              --]]
              socket.setsockopt(clientfd, socket.SOL_SOCKET, socket.SO_RCVTIMEO, 5, 0)
              local readf  = assert(stdio.fdopen(clientfd, "r"))
              local clientfd2 = assert(unistd.dup(clientfd))
              local writef = assert(stdio.fdopen(clientfd2, "w"))
              -- Use pcall() to catch any errors. The connection is closed regardless.
              local ok, errstr, errnum = pcall(main.handle_request, readf, writef)
              if not ok then
                print(errstr, errnum)
              end
              readf:close()
              writef:close()
              main.child_is_ready(wpipe, padded_pid)
            else
              if errnum == errno.EAGAIN or errnum == errno.EWOULDBLOCK then
                -- accept() timed out due to SO_RCVTIMEO.
                -- TODO: also take a timestamp before accept to tell the difference 
                -- between SO_RCVTIMEO and accept returning EAGAIN due to thundering 
                -- herd.
                if exit_on_timeout then
                  unistd._exit(0)
                end
              end
            end
          end
        end
      elseif ret == 0 then
        -- poll() timeout.
        if exit_on_timeout then
          unistd._exit(0)
        end
      end
    end
  end
end

if os.getenv("TEST") ~= "1" then
  main.parent_loop()
end

-- Tests below this line:
------------------------------------------------------------------------------------------

if os.getenv("TEST") == "1" then
  local childpid = assert(unistd.fork())
  if childpid == 0 then
    -- The server process.
    main.parent_loop()
  else
    -- The test process.
    -- local inspect = require("inspect")
    local function connect()
      local fd = socket.socket(socket.AF_INET, socket.SOCK_STREAM, 0)
      local addr = socket.getaddrinfo("127.0.0.1", "8080", {
        family = socket.AF_INET, socktype = socket.SOCK_STREAM 
      })
      assert(socket.connect(fd, addr[1]))
      local readf = assert(stdio.fdopen(fd, "r"))
      local writef = assert(stdio.fdopen(fd, "w"))
      writef:setvbuf("no")
      return readf, writef
    end
    
    local function GET(uri)
      local readf, writef = connect()
      local request_line = ("GET %s HTTP/1.1\r\n\r\n"):format(uri)
      writef:write(request_line)
      local status_line = readf:read("*L")
      if not status_line then
        return
      end
      local status, reason = http.parse_response_line(status_line)
      local headers = {}
      while true do
        local header = readf:read("*L")
        assert(header)
        if header == "\r\n" then
          break
        end
        local name, value = http.parse_header(header)
        headers[name:lower()] = value
      end
      readf:close()
      writef:close()
      local response = {
        status = status,
        reason = reason,
        headers = headers,
      }
      return response
    end
    
    local function invalid_requests()
      local requests = {
        "GET / HTTP/1.1",
        "GET / HTTP/1.1\r\n",
        "GET / HTTP/1.1\r\n" .. "Name: " .. (" "):rep(8192) .. "\r\n\r\n",
      }
      for _, request in ipairs(requests) do
        local readf, writef = connect()
        writef:write(request)
        -- readf:read("*L")
        readf:close()
        writef:close()
      end
    end
    
    local function slowloris()
      local connections = {}
      for i = 1, 500 do
        local readf, writef = connect()
        writef:write("GET")
        table.insert(connections, {readf = readf, writef = writef})
      end
      unistd.sleep(60)
      for _, connection in ipairs(connections) do
        connection.readf:close()
        connection.writef:close()
      end
    end
  
    local function test()
      local res = GET("/")
      -- print(inspect(res))
      assert(res.reason == "OK")
      
      -- slowloris(); do return end
      
      -- invalid_requests(); do return end
      
      for i = 1, 1000 do
        for route, _ in pairs(config.routes) do
          -- print("GET", route)
          local res = GET(route)
          if not res or not (res.status == 200 or res.status == 204) then
            print(route)
            -- print(inspect(res))
            error()
          end
        end
      end
    end
    
    local ok, errstr = pcall(test)
    if not ok then
      print(errstr)
    else
      print("modserver.lua test complete")
    end
    
    signal.kill(0, signal.SIGKILL)
    while (wait.wait()) do
      -- Wait for children to exit.
    end
  end
end
