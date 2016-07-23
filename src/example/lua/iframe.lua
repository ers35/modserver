local servlet = {}

function servlet:run()
  self:rwrite([[
<!DOCTYPE html>
<html>
<head>
<title>iframe</title>
<style>
iframe {
  height: 35px;
  margin-bottom: 5px;
  display: block;
}
</style>
</head>
<body>
]])
  local servlets = {
    "/example/c/hello.c.so",
    "/example/c++/hello.cpp.so",
    "/example/cgi/hello.cgi",
    "/example/d/hello.d.so",
    "/example/go/hello.go.so",
    "/example/haskell/hello.hs.so",
    "/example/lua/hello.lua",
    "/example/nim/hello.nim.so",
    -- "/example/ocaml/hello.ml.so",
    "/example/python/hello.py",
    "/example/ruby/hello.rb",
    "/example/rust/hello.rs.so",
  }
  for i, servlet in ipairs(servlets) do
    self:rwrite(([[<a href="%s">%s</a>]] .. "\n"):format(servlet, servlet))
    self:rwrite(([[<iframe src="%s"></iframe>]] .. "\n"):format(servlet))
  end
  self:rwrite([[
</body>
</html>
]])
end

return servlet
