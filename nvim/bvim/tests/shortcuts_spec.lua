package.path = vim.fn.getcwd() .. "/lua/?.lua;" .. vim.fn.getcwd() .. "/lua/?/init.lua;" .. package.path

require("upsc_notes.config").setup()

local shortcuts = require("upsc_notes.shortcuts")

local actions = setmetatable({}, {
  __index = function()
    return function() end
  end,
})

local function assert_unique(items, key_fn, label)
  local seen = {}
  for _, item in ipairs(items) do
    local key = key_fn(item)
    if seen[key] then
      error(("duplicate %s: %s"):format(label, key))
    end
    seen[key] = true
  end
end

assert_unique(shortcuts.global(actions), function(shortcut)
  return shortcut.mode .. " " .. shortcut.lhs
end, "global shortcut")

assert_unique(shortcuts.tree_buffer(actions), function(shortcut)
  return shortcut.mode .. " " .. shortcut.lhs
end, "tree shortcut")

assert_unique(shortcuts.dashboard_buttons({
  dashboard = {
    zettel_tree = "T",
    in_tree = "I",
    zettel_note = "Z",
    in_note = "N",
    recent = "O",
    search = "S",
    quit = "Q",
  },
}), function(button)
  return button.key
end, "dashboard key")

assert_unique(shortcuts.which_key_groups(), function(group)
  return group[1]
end, "which-key group")
