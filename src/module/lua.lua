local mod = {}

function mod.load_servlet(path)
  local chunk = assert(loadfile(path))
  local servlet = chunk()
  assert(servlet.run, "The servlet must have a run() function: " .. path)
  return servlet
end

return mod
