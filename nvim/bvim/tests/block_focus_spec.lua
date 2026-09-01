package.path = vim.fn.getcwd() .. "/lua/?.lua;" .. vim.fn.getcwd() .. "/lua/?/init.lua;" .. package.path

local block_focus = require("upsc_notes.block_focus")

local function assert_eq(actual, expected, message)
  if not vim.deep_equal(actual, expected) then
    error(("%s\nexpected: %s\nactual: %s"):format(message, vim.inspect(expected), vim.inspect(actual)), 2)
  end
end

local lines = {
  "- root",
  "  - child",
  "",
  "    - grandchild",
  "- sibling",
  "  - sibling child",
}

local first, last = block_focus.block_range(lines, 1)
assert_eq({ first, last }, { 1, 4 }, "root includes its indented block")

first, last = block_focus.block_range(lines, 2)
assert_eq({ first, last }, { 1, 4 }, "child keeps its complete parent branch focused")

first, last = block_focus.block_range(lines, 4)
assert_eq({ first, last }, { 1, 4 }, "grandchild keeps every ancestor and the complete branch focused")

first, last = block_focus.block_range(lines, 5)
assert_eq({ first, last }, { 5, 6 }, "next sibling starts a new block")

first, last = block_focus.block_range(lines, 6)
assert_eq({ first, last }, { 5, 6 }, "a child in the next branch focuses that branch's parent")

first, last = block_focus.block_range(lines, 3)
assert_eq({ first, last }, { 3, 3 }, "blank line focuses itself")

local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_set_current_buf(buf)
vim.bo[buf].filetype = "markdown"
vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
vim.api.nvim_win_set_cursor(0, { 1, 0 })

block_focus.enable({ notify = false })
assert_eq(block_focus.is_enabled(buf), true, "focus mode enabled")

local marks = vim.api.nvim_buf_get_extmarks(buf, -1, 0, -1, {})
assert_eq(#marks, 2, "focused block and remaining note are highlighted")

vim.api.nvim_win_set_cursor(0, { 5, 0 })
block_focus.refresh(buf)
marks = vim.api.nvim_buf_get_extmarks(buf, -1, 0, -1, {})
assert_eq(#marks, 2, "highlights refresh for the new block")

block_focus.disable({ notify = false })
assert_eq(block_focus.is_enabled(buf), false, "focus mode disabled")
marks = vim.api.nvim_buf_get_extmarks(buf, -1, 0, -1, {})
assert_eq(#marks, 0, "disabling focus clears highlights")

vim.api.nvim_buf_delete(buf, { force = true })
