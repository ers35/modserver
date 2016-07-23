local servlet = {}

function servlet:run()
  local method = self:get_method()
  if method == "GET" then
    -- display upload page
    self:rwrite([[
<!DOCTYPE html>
<html>
<head><title>Upload File</title></head>
<body>
<form method="POST" enctype="multipart/form-data">
  <input type="file" name="thefile" id="thefile">
  <input type="submit" value="Upload File" name="submit">
</form>
</body>
</html>
    ]])
  elseif method == "POST" then
    -- handle upload
    local tmpfile = io.tmpfile()
    -- read the body
    while true do
      local body_part = self:read_body(4096)
      if body_part then
        tmpfile:write(body_part)
      else
        break
      end
    end
    -- write the body back to the client
    tmpfile:seek("set")
    self:rwrite("<pre>")
    while true do
      local body_part = tmpfile:read(4096)
      if body_part then
        self:rwrite(body_part)
      else
        break
      end
    end
    self:rwrite("</pre>")
    tmpfile:close()
  end
end

return servlet
