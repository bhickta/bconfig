local context = require("upsc_notes.note_context")
local fs = require("upsc_notes.fs")
local paths = require("upsc_notes.paths")

local M = {}

function M.open_vault_tree()
  context.open_tree_at(paths.vault_root)
end

function M.open_zettel_tree()
  context.open_tree_at(paths.zettel_root)
end

function M.open_in_tree()
  context.open_tree_at(paths.in_root)
end

function M.reveal_current_note()
  local current = context.active_note_path()
  if current == "" then
    M.open_zettel_tree()
    return
  end
  local dir = fs.is_directory(current) and current or vim.fn.fnamemodify(current, ":h")
  context.open_tree_at(dir, fs.is_file(current) and current or nil)
end

function M.focus_tree()
  local current = context.active_note_path()
  context.open_tree_at(context.current_scope_dir(), fs.is_file(current) and current or nil)
end

function M.unfocus_tree()
  context.open_tree_at(context.active_root_dir())
end

function M.open_zettelkasten_dir()
  vim.cmd("edit " .. vim.fn.fnameescape(paths.zettel_root))
end

function M.open_in_dir()
  vim.cmd("edit " .. vim.fn.fnameescape(paths.in_root))
end

function M.toggle_tree()
  require("neo-tree.command").execute({
    action = "focus",
    source = "filesystem",
    position = "left",
    dir = context.active_root_dir(),
    toggle = true,
  })
end

function M.toggle_tree_focus()
  local current_win = vim.api.nvim_get_current_win()
  if context.is_tree_window(current_win) then
    vim.cmd("wincmd p")
    return
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if context.is_tree_window(win) then
      vim.api.nvim_set_current_win(win)
      return
    end
  end
  M.reveal_current_note()
end

function M.focus_tree_panel()
  if vim.bo.filetype == "neo-tree" then
    vim.cmd.wincmd("p")
  else
    require("neo-tree.command").execute({
      action = "focus",
      source = "filesystem",
      position = "left",
      dir = context.active_root_dir(),
    })
  end
end

return M
