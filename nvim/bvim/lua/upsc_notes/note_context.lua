local fs = require("upsc_notes.fs")
local paths = require("upsc_notes.paths")

local M = {}

local function in_vault(path)
  return fs.is_within(paths.vault_root, path)
end

function M.active_note_path()
  local current = vim.api.nvim_buf_get_name(0)
  if in_vault(current) and (fs.is_file(current) or fs.is_directory(current)) then
    return current
  end

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype ~= "neo-tree" then
      local name = vim.api.nvim_buf_get_name(buf)
      if in_vault(name) and (fs.is_file(name) or fs.is_directory(name)) then
        return name
      end
    end
  end

  local alternate = vim.fn.bufname("#")
  if in_vault(alternate) and (fs.is_file(alternate) or fs.is_directory(alternate)) then
    return alternate
  end
  return ""
end

function M.current_scope_dir()
  local current = M.active_note_path()
  if current == "" then
    return paths.zettel_root
  end
  return fs.is_directory(current) and current or vim.fn.fnamemodify(current, ":h")
end

function M.active_root_dir()
  local current = M.active_note_path()
  return current ~= "" and fs.is_within(paths.in_root, current) and paths.in_root or paths.zettel_root
end

function M.is_tree_window(win)
  return vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "neo-tree"
end

function M.open_tree_at(path, reveal_file)
  if not fs.is_directory(path) then
    vim.notify("Tree root does not exist: " .. path, vim.log.levels.WARN)
    return false
  end

  require("neo-tree.command").execute({
    action = "focus",
    source = "filesystem",
    position = "left",
    dir = path,
    reveal_file = reveal_file,
    reveal_force_cwd = reveal_file ~= nil,
  })
  return true
end

return M
