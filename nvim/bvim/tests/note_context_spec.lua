package.path = vim.fn.getcwd() .. "/lua/?.lua;" .. vim.fn.getcwd() .. "/lua/?/init.lua;" .. package.path

local config = require("upsc_notes.config")
local function assert_eq(actual, expected, message)
  if actual ~= expected then
    error(("%s\nexpected: %s\nactual: %s"):format(message, vim.inspect(expected), vim.inspect(actual)), 2)
  end
end

local root = vim.fn.tempname()
local zettel = vim.fs.joinpath(root, "zettelkasten")
local inbox = vim.fs.joinpath(root, "in")
vim.fn.mkdir(zettel, "p")
vim.fn.mkdir(inbox, "p")
local zettel_note = vim.fs.joinpath(zettel, "note.md")
local inbox_note = vim.fs.joinpath(inbox, "capture.md")
vim.fn.writefile({ "zettel" }, zettel_note)
vim.fn.writefile({ "inbox" }, inbox_note)
config.setup({ vault = { root = root } })

local context = require("upsc_notes.note_context")
vim.cmd.edit(vim.fn.fnameescape(zettel_note))
assert_eq(context.active_note_path(), zettel_note, "current vault note should be active")
assert_eq(context.current_scope_dir(), zettel, "file scope should be its parent directory")
assert_eq(context.active_root_dir(), zettel, "zettel notes should use the zettelkasten root")

vim.cmd.edit(vim.fn.fnameescape(inbox_note))
assert_eq(context.active_root_dir(), inbox, "inbox notes should use the in root")

local prefix_sibling = root .. "-other"
vim.fn.mkdir(prefix_sibling, "p")
local outside = vim.fs.joinpath(prefix_sibling, "outside.md")
vim.fn.writefile({ "outside" }, outside)
vim.cmd.edit(vim.fn.fnameescape(outside))
assert_eq(context.active_note_path(), inbox_note, "path-prefix siblings should not be treated as vault files")

vim.cmd.bdelete({ bang = true })
vim.fn.delete(root, "rf")
vim.fn.delete(prefix_sibling, "rf")
