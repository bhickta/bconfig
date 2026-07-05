local config = require("upsc_notes.config")

return setmetatable({}, {
  __index = function(_, key)
    return config.get().paths[key]
  end,
})
