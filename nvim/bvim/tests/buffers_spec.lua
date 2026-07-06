package.path = vim.fn.getcwd() .. "/lua/?.lua;" .. vim.fn.getcwd() .. "/lua/?/init.lua;" .. package.path

require("upsc_notes.config").setup()

local actions = require("upsc_notes.actions")

local function assert_eq(actual, expected, message)
  if actual ~= expected then
    error(("%s\nexpected: %s\nactual: %s"):format(message or "assertion failed", vim.inspect(expected), vim.inspect(actual)), 2)
  end
end

local function assert_true(value, message)
  if not value then
    error(message or "assertion failed", 2)
  end
end

local tmp = vim.fn.tempname()
vim.fn.mkdir(tmp, "p")

local files = {
  tmp .. "/one.md",
  tmp .. "/two.md",
  tmp .. "/three.md",
}

for _, file in ipairs(files) do
  vim.fn.writefile({ "# " .. vim.fn.fnamemodify(file, ":t:r") }, file)
end

vim.cmd.edit(vim.fn.fnameescape(files[1]))
vim.cmd.edit(vim.fn.fnameescape(files[2]))
vim.cmd.edit(vim.fn.fnameescape(files[3]))
vim.cmd.buffer(vim.fn.bufnr(files[1]))

local first = vim.fn.bufnr(files[1])
local second = vim.fn.bufnr(files[2])
local third = vim.fn.bufnr(files[3])

actions.next_buffer()
assert_eq(vim.api.nvim_get_current_buf(), second, "next_buffer should move to the next listed buffer")

actions.prev_buffer()
assert_eq(vim.api.nvim_get_current_buf(), first, "prev_buffer should move to the previous listed buffer")

actions.alternate_buffer()
assert_eq(vim.api.nvim_get_current_buf(), second, "alternate_buffer should jump to the alternate buffer")

actions.close_buffer()
assert_true(not vim.bo[second].buflisted, "close_buffer should unlist the current buffer")
assert_true(vim.api.nvim_get_current_buf() ~= second, "close_buffer should leave a usable current buffer")

vim.cmd.buffer(first)
actions.close_other_buffers()
assert_true(vim.bo[first].buflisted, "close_other_buffers should keep the current buffer")
assert_true(not vim.bo[third].buflisted, "close_other_buffers should close other listed buffers")

vim.fn.delete(tmp, "rf")
