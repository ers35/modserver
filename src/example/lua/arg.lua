local servlet = {}

-- http://127.0.0.1:8080/arg?name=kenny

function servlet:run()
  local name = self:get_arg("name") or "no name"
  self:rwrite("hello, " .. name)
end

return servlet
