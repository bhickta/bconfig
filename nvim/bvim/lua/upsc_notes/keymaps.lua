local actions = require("upsc_notes.actions")
local shortcuts = require("upsc_notes.shortcuts")

local M = {}

local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { silent = true, noremap = true, desc = desc })
end

function M.setup()
  for _, shortcut in ipairs(shortcuts.global(actions)) do
    map(shortcut.mode, shortcut.lhs, shortcut.rhs, shortcut.desc)
  end
end

return M
