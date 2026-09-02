package.path = vim.fn.getcwd() .. "/lua/?.lua;" .. vim.fn.getcwd() .. "/lua/?/init.lua;" .. package.path

require("upsc_notes.config").setup()

local function assert_eq(actual, expected, message)
  if not vim.deep_equal(actual, expected) then
    error(("%s\nexpected: %s\nactual: %s"):format(message, vim.inspect(expected), vim.inspect(actual)), 2)
  end
end

local root = vim.fn.tempname()
vim.fn.mkdir(root, "p")
local recent_entries = { { root = root, updated_at = 100, position = { line = 5 } } }
local opened_root
package.loaded["upsc_notes.folder_reader"] = {
  recent = function()
    return recent_entries
  end,
  open = function(folder)
    opened_root = folder
  end,
}

local recent_views = require("upsc_notes.recent_views")
local items = recent_views.items()
assert_eq(#items, 1, "recent Folder Views should create picker items")
assert_eq(items[1].folder_root, root, "Folder View picker items should retain their root")

local opts = recent_views.picker_options(items)
assert_eq(opts.multi[2].source, "recent", "normal recent files should remain an unchanged picker source")
assert_eq(opts.multi[1].finder()[1].folder_root, root, "Folder View source should expose persisted roots")

local closed = false
opts.confirm({
  close = function()
    closed = true
  end,
}, items[1])
vim.wait(100, function() return opened_root ~= nil end)
assert_eq(closed, true, "selecting a Folder View should close the recent picker")
assert_eq(opened_root, root, "selecting a Folder View should reopen it through the folder reader")

local actual_actions = package.loaded["snacks.picker.actions"]
local jumped_item
package.loaded["snacks.picker.actions"] = {
  jump = function(_, item)
    jumped_item = item
  end,
}
local recent_file = { file = root .. "/normal.md" }
opts.confirm({}, recent_file, {})
assert_eq(jumped_item, recent_file, "normal recent files should retain Snacks' standard confirm action")
package.loaded["snacks.picker.actions"] = actual_actions

local captured_options
local normal_recent_calls = 0
package.loaded.snacks = {
  picker = {
    pick = function(picker_options)
      captured_options = picker_options
    end,
    recent = function()
      normal_recent_calls = normal_recent_calls + 1
    end,
  },
}
package.loaded["upsc_notes.actions"] = nil
local actions = require("upsc_notes.actions")
actions.find_recent_files()
assert_eq(captured_options.title, "Recent files and Folder Views", "dashboard o should use the combined picker")
assert_eq(normal_recent_calls, 0, "combined recents should not open a second picker")

recent_entries = {}
captured_options = nil
actions.find_recent_files()
assert_eq(captured_options, nil, "empty Folder View history should not change the normal recent picker")
assert_eq(normal_recent_calls, 1, "normal recent picker should remain the fallback")

vim.fn.delete(root, "rf")
