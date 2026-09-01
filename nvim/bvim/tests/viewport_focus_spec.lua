package.path = vim.fn.getcwd() .. "/lua/?.lua;" .. vim.fn.getcwd() .. "/lua/?/init.lua;" .. package.path

local viewport = require("upsc_notes.viewport_focus")

local function assert_eq(actual, expected, message)
  if not vim.deep_equal(actual, expected) then
    error(("%s\nexpected: %s\nactual: %s"):format(message, vim.inspect(expected), vim.inspect(actual)), 2)
  end
end

require("upsc_notes.options").setup()

local buf = vim.api.nvim_create_buf(false, false)
vim.api.nvim_set_current_buf(buf)
local lines = {}
for line = 1, 120 do
  lines[line] = ("line %d"):format(line)
end
vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
vim.api.nvim_win_set_cursor(0, { 60, 0 })

local win = vim.api.nvim_get_current_win()
local expected_offset = viewport.target_offset(vim.api.nvim_win_get_height(win))
assert_eq(viewport.place(win), true, "file view should support proportional cursor placement")
assert_eq(vim.api.nvim_win_get_cursor(win)[1], 60, "viewport placement should not move the cursor")
assert_eq(60 - vim.fn.line("w0"), expected_offset, "cursor should sit thirty percent from the top")

viewport.setup()
vim.api.nvim_win_set_cursor(win, { 80, 0 })
vim.api.nvim_exec_autocmds("CursorMoved", { buffer = buf })
assert_eq(80 - vim.fn.line("w0"), expected_offset, "cursor movement should restore the thirty-percent position")

local scroll_down = vim.api.nvim_replace_termcodes("<C-e>", true, false, true)
vim.cmd("normal! 3" .. scroll_down)
vim.api.nvim_exec_autocmds("WinScrolled", { pattern = tostring(win) })
assert_eq(80 - vim.fn.line("w0"), expected_offset, "manual viewport scrolling should restore the focus position")

local utility = vim.api.nvim_create_buf(false, true)
vim.api.nvim_set_current_buf(utility)
assert_eq(viewport.place(vim.api.nvim_get_current_win()), false, "utility buffers should retain their own scrolling")

vim.api.nvim_buf_delete(buf, { force = true })
vim.api.nvim_buf_delete(utility, { force = true })
