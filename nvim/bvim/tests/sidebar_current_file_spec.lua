package.path = vim.fn.getcwd() .. "/lua/?.lua;" .. vim.fn.getcwd() .. "/lua/?/init.lua;" .. package.path

require("upsc_notes.config").setup()
local opts = require("upsc_notes.plugins.configs.neo-tree").opts()

local handler
for _, event_handler in ipairs(opts.event_handlers) do
  if event_handler.id == "upsc_current_file_line" then
    handler = event_handler.handler
    break
  end
end
if not handler then
  error("Neo-tree should reapply the current-file line highlight after every render")
end

local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "other.md", "active.md", "later.md" })
local active_path = vim.fs.normalize("/notes/active.md")
local looked_up_path
local tree = {
  get_node = function(_, path)
    looked_up_path = path
    if path == active_path then
      return { id = path }, 2
    end
  end,
}
vim.t.upsc_active_file = active_path

handler({ name = "filesystem", bufnr = buf, tree = tree })
if looked_up_path ~= active_path then
  error("full-row highlight should look up the tracked editor file")
end
local highlighted_row
for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(buf, -1, 0, -1, { details = true })) do
  if mark[4].line_hl_group == "UpscNeoTreeCurrentLine" then
    highlighted_row = mark[2]
  end
end
if highlighted_row ~= 1 then
  error("full-row highlight should follow Neo-tree's active file row")
end

vim.t.upsc_active_file = vim.fs.normalize("/notes/missing.md")
handler({ name = "filesystem", bufnr = buf, tree = tree })
for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(buf, -1, 0, -1, { details = true })) do
  if mark[4].line_hl_group == "UpscNeoTreeCurrentLine" then
    error("stale current-file line highlights should be removed after redraw")
  end
end

vim.api.nvim_buf_delete(buf, { force = true })
