local mod = {}

function mod.load_servlet(path)
  local servlet = {
    -- init is optional.
    init = package.loadlib(path, "init"),
    run = assert(package.loadlib(path, "run")),
  }
  return servlet
end

return mod
