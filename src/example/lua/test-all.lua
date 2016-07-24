local servlet = {}

function servlet:run()
  self:rwrite([[
<!DOCTYPE html>
<html>
<head>
<title>iframe</title>
<style>
iframe {
  height: 80px;
  margin-bottom: 5px;
  display: block;
  overflow: auto;
}
</style>
</head>
<body>
]])
  local servlets = {
    "/example/c/test.c.so",
    "/example/crystal/test.cr.so",
    "/example/cgi/test.cgi",
    "/example/d/test.d.so",
    "/example/go/test.go.so",
    "/example/haskell/test.hs.so",
    "/example/lua/test.lua",
    "/example/nim/test.nim.so",
    "/example/python/test.py",
    "/example/ruby/test.rb",
    "/example/rust/test.rs.so",
  }
  for i, servlet in ipairs(servlets) do
    self:rwrite(([[<a href="%s?arg=123">%s</a>]] .. "\n"):format(servlet, servlet))
    self:rwrite(([[<iframe src="%s?arg=123"></iframe>]] .. "\n"):format(servlet))
  end
  self:rwrite([[
</body>
</html>
]])
end

return servlet
