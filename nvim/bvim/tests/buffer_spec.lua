package.path = vim.fn.getcwd() .. "/lua/?.lua;" .. vim.fn.getcwd() .. "/lua/?/init.lua;" .. package.path

local buffer = require("upsc_notes.buffer")

local function assert_eq(actual, expected, message)
  if actual ~= expected then
    error(("%s\nexpected: %s\nactual: %s"):format(message, vim.inspect(expected), vim.inspect(actual)), 2)
  end
end

local note = vim.api.nvim_create_buf(false, false)
vim.bo[note].filetype = "markdown"
assert_eq(buffer.is_readable_markdown(note), true, "normal Markdown notes support reading features")

local folder = vim.api.nvim_create_buf(false, true)
vim.bo[folder].buftype = "nofile"
vim.bo[folder].filetype = "markdown"
vim.b[folder].upsc_folder_reader_root = "/notes/focused"
vim.bo[folder].modifiable = false
assert_eq(buffer.is_folder_reader(folder), true, "combined folder buffers are identified")
assert_eq(buffer.is_readable_markdown(folder), true, "combined folder buffers support reading features")
assert_eq(buffer.is_standard_or_folder(folder), true, "combined folder buffers support standard editor UI features")
vim.api.nvim_set_current_buf(folder)
require("upsc_notes.actions").set_edit_mode({ notify = false })
assert_eq(vim.bo[folder].modifiable, false, "combined folder content remains protected from editing")

local utility = vim.api.nvim_create_buf(false, true)
vim.bo[utility].buftype = "nofile"
vim.bo[utility].filetype = "markdown"
assert_eq(buffer.is_readable_markdown(utility), false, "unrelated scratch buffers remain excluded")
assert_eq(buffer.is_standard_or_folder(utility), false, "unrelated scratch buffers remain excluded from editor UI")

vim.api.nvim_buf_delete(note, { force = true })
vim.api.nvim_buf_delete(folder, { force = true })
vim.api.nvim_buf_delete(utility, { force = true })
