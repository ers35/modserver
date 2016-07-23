local mod = {}

local function run(self, path)
  local f = io.popen(path)
  if f then
    while true do
      -- 6.2.  Response Types
      -- https://tools.ietf.org/html/rfc3875#section-6.2
      local header = f:read("*l")
      if not header or #header == 0 then
        break
      end
      local key, value = header:match("([%a-]+)%s*:%s*(.+)")
      if key and value then
        self:set_header(key, value)
      end
    end
    while true do
      local body = f:read(4096)
      if not body then
        break
      end
      self:rwrite(body)
    end
    f:close()
  end
end

function mod.load_servlet(path)
  local servlet = {}
  
  function servlet:run()
    run(self, path)
  end
  
  return servlet
end

return mod

-- https://tools.ietf.org/html/rfc3875
