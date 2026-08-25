package.path = vim.fn.getcwd() .. "/lua/?.lua;" .. vim.fn.getcwd() .. "/lua/?/init.lua;" .. package.path

require("upsc_notes.config").setup()

local function assert_eq(actual, expected, message)
  if actual ~= expected then
    error(("%s\nexpected: %s\nactual: %s"):format(message, vim.inspect(expected), vim.inspect(actual)), 2)
  end
end

require("upsc_notes.options").setup()
assert_eq(vim.wo.number, false, "absolute numbers are disabled by default")
assert_eq(vim.wo.relativenumber, true, "relative numbers are enabled by default")

local status = require("upsc_notes.astroui.status")
assert_eq(status.relative_line_number(0, 0), "%#CursorLineNr#0 ", "current line displays zero")
assert_eq(status.relative_line_number(3, 0), "%#LineNr#3 ", "other lines display relative distance")
assert_eq(status.relative_line_number(0, 1), "%=", "virtual lines do not display a number")

local original_heirline = package.loaded.heirline
local heirline_config
package.loaded.heirline = {
  setup = function(opts) heirline_config = opts end,
}
status.setup()
assert_eq(vim.tbl_contains(heirline_config.statusline[10].update, "User"), true, "reading time reacts to speed changes")
assert_eq(
  vim.tbl_contains(heirline_config.statusline[11].update, "User"),
  true,
  "folder reading time reacts to speed changes"
)
package.loaded.heirline = original_heirline

local actions = require("upsc_notes.actions")
vim.bo.filetype = "markdown"

actions.set_read_mode({ notify = false })
assert_eq(vim.wo.number, false, "read mode keeps absolute numbers disabled")
assert_eq(vim.wo.relativenumber, true, "read mode keeps relative numbers enabled")

actions.set_edit_mode({ notify = false })
assert_eq(vim.wo.number, false, "edit mode keeps absolute numbers disabled")
assert_eq(vim.wo.relativenumber, true, "edit mode keeps relative numbers enabled")
