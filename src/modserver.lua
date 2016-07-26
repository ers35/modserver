-- The author disclaims copyright to this source code.

local api = require("api.lua.modserver")
local config = require("config")
local http = require("http")
--[[
luaposix provides access to the POSIX standards for functionality Lua lacks such as 
networking. See https://github.com/luaposix/luaposix for more details.
]]
local errno = require("posix.errno")
local fcntl = require("posix.fcntl")
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
end

local main = {}

--[[
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

local function set_signal_handlers()
  for _, signal_name in ipairs{
    "SIGINT",
    "SIGSEGV",
    "SIGABRT",
    "SIGFPE",
    "SIGILL",
    "SIGBUS",
    "SIGPIPE",
  } do
    signal.signal(signal[signal_name], signal.SIG_DFL)
  end
end

local function set_nonblocking(fd)
  local flags = fcntl.fcntl(fd, fcntl.F_GETFL)
  fcntl.fcntl(fd, fcntl.F_SETFL, bit32.bor(flags, fcntl.O_NONBLOCK))
end

function main.parent_loop()
  -- Setup TCP networking.
  local serverfd = assert(socket.socket(socket.AF_INET, socket.SOCK_STREAM, 0))
  assert(socket.setsockopt(serverfd, socket.SOL_SOCKET, socket.SO_REUSEADDR, 1))
  assert(socket.bind(
    serverfd, {family = socket.AF_INET, addr = "0.0.0.0", port = config.cfg.listen}
  ), "unable to listen on port: " .. config.cfg.listen)
  assert(socket.listen(serverfd, 1024))
  -- The children socket inherits this option on a fork.
  assert(socket.setsockopt(serverfd, socket.SOL_SOCKET, socket.SO_RCVTIMEO, 5, 0))

  -- The parent and children communicate over a pipe.
  local rpipe, wpipe = unistd.pipe()

  set_signal_handlers()
  
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
  set_nonblocking(rpipe)

  local num_fork = 0
  -- Keep track of forked child processes by their pid.
  local children = {}
  local num_children_ready = 0
  while true do
    --[[
    The parent process forks a child process when there are no ready child processes. A 
    ready child process is one that is waiting to accept a client connection. 
    --]]
    assert(num_children_ready >= 0, "negative children ready")
    if num_children_ready == 0 then
      local childpid = assert(unistd.fork())
      if childpid == 0 then
        -- a new child process
        unistd.close(rpipe)
        main.child_loop(num_fork, wpipe, serverfd)
        error("returned from child_loop()")
      elseif childpid > 0 then
        -- the same parent process
        children[childpid] = {state = "f"}
        num_fork = num_fork + 1
      end
    end
    
    --[[
    
    --]]
    local ret = poll.poll(poll_fds, 1000)
    if ret == 1 then
      for fd in pairs(poll_fds) do
        if poll_fds[fd].revents.IN then
          repeat
            -- The parent waits on one pipe for messages from many children.
            local data, errmsg, errnum = unistd.read(rpipe, 21 * 128)
            if data then
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
    Wait for state changes in the child processes, if any.
    --]]
    repeat
      local pid, status, code = wait.wait(-1, wait.WNOHANG)
      if pid and pid ~= 0 then
        -- print(pid, status, code)
        local child = children[pid]
        if child and child.state == "+" then
          num_children_ready = num_children_ready - 1
        end
        children[pid] = nil
        if code == signal.SIGSEGV then
          print(pid, status)
        end
      end
    until not pid or pid == 0 or pid == -1
  end
end

--[[
Read the request, choose the servlet to handle the request, run the servlet, and close 
the connection.
--]]
function main.handle_request(clientfd)
  local clientfd_read = stdio.fdopen(clientfd, "r")
  local clientfd2 = unistd.dup(clientfd)
  local clientfd_write = stdio.fdopen(clientfd2, "w")
  --[[
  A slow client can send one byte every five seconds up to LUAL_BUFFERSIZE before the 
  connection is closed.
  --]]
  local request = http.read_and_parse_request_from_file(clientfd_read)
  if request and request.method and request.uri and request.uri_path then
    local state = {
      request = request,
      content_length_read = 0,
      headers_written = false,
      clientfd_read = clientfd_read,
      clientfd_write = clientfd_write,
      headers = {},
    }
    setmetatable(state, {__index = api})
    local servlet = config.routes[request.uri_path]
    if servlet then
      if servlet.num_run == 0 then
        if servlet.init then
          servlet.init(state)
          -- Override languages that set their own signal handlers.
          set_signal_handlers()
          signal.signal(signal.SIGCHLD, signal.SIG_DFL)
        end
      end
      servlet.run(state)
      servlet.num_run = servlet.num_run + 1
    else
      -- No servlet can handle the request.
      state:set_status(404)
      state:rwrite("404 Not Found")
    end
    if not state.headers_written then
      -- The servlet did not write any body. Write an empty body.
      state:rwrite("")
    end
    if not state.headers["content-length"] then
      -- Send the last chunk of the chunked response.
      state.clientfd_write:write("0\r\n\r\n")
      state.clientfd_write:flush()
    end
  end
  clientfd_read:close()
  clientfd_write:close()
end

--[[
Each child process waits to accept one connection on the same server socket. The kernel 
load balances the connections across all child processes. The child tells the parent of 
two events: before the child waits on accept and after the child accepts a connection. 
The parent uses these events to keep track of how many child are ready to handle new 
connections.
--]]
function main.child_loop(id, wpipe, serverfd)
  local mypid = unistd.getpid()
  local padded_pid = ("%020u"):format(mypid)
  main.child_is_ready(wpipe, padded_pid)
  while true do
    local clientfd, errmsg, errnum = socket.accept(serverfd)
    if clientfd then
      main.child_is_busy(wpipe, padded_pid)
      --[[
      A read from the socket returns with an error after five seconds of inactivity 
      rather than blocking forever.
      --]]
      socket.setsockopt(clientfd, socket.SOL_SOCKET, socket.SO_RCVTIMEO, 5, 0)
      main.handle_request(clientfd)
      main.child_is_ready(wpipe, padded_pid)
    else
      if (errnum == errno.EAGAIN or errnum == errno.EWOULDBLOCK) and id > 0 then
        -- accept() timed out due to SO_RCVTIMEO.
        -- TODO: also take a timestamp before accept to tell the difference between 
        -- SO_RCVTIMEO and accept returning EAGAIN due to thundering herd.
        unistd._exit(0)
      end
    end
  end
end

main.parent_loop()
