local servlet = {}

function servlet:run()
  local f = io.open("example/lua/file.lua", "r")
  if f then
    local length = f:seek("end")
    f:seek("set")
    self:set_content_length(length)
    self:set_header("Content-Type", "text/plain; charset=UTF-8");
    while true do
      local buf = f:read(4096)
      if buf then
        self:rwrite(buf)
      else
        break
      end
    end
    f:close()
  else
    self:rwrite("file not found")
  end
end

return servlet
