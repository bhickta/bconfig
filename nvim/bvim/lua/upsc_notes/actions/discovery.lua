local config = require("upsc_notes.config")
local context = require("upsc_notes.note_context")
local fs = require("upsc_notes.fs")
local paths = require("upsc_notes.paths")

local M = {}

local function telescope()
  return require("telescope.builtin")
end

local function snacks_picker()
  local ok, snacks = pcall(require, "snacks")
  return ok and snacks.picker or nil
end

local function file_command()
  for _, executable in ipairs({ "rg", "fd", "fdfind" }) do
    if vim.fn.executable(executable) == 1 then
      return executable
    end
  end
  return "find"
end

local function find_files(opts)
  if not fs.is_directory(opts.cwd) then
    vim.notify("File search root does not exist: " .. opts.cwd, vim.log.levels.WARN)
    return
  end

  opts.hidden = true
  opts.ignored = false
  opts.cmd = opts.cmd or file_command()
  opts = config.picker_defaults(opts)

  local picker = snacks_picker()
  if picker then
    picker.files(opts)
  else
    telescope().find_files({ cwd = opts.cwd, prompt_title = opts.title or opts.prompt_title })
  end
end

local function grep(opts)
  if not fs.is_directory(opts.cwd) then
    vim.notify("Content search root does not exist: " .. opts.cwd, vim.log.levels.WARN)
    return
  end
  if vim.fn.executable("rg") ~= 1 then
    vim.notify("Content search needs ripgrep: install rg for live grep.", vim.log.levels.WARN)
    return
  end

  opts.hidden = true
  opts.ignored = false
  opts = config.picker_defaults(opts)

  local picker = snacks_picker()
  if picker then
    picker.grep(opts)
  else
    telescope().live_grep({
      cwd = opts.cwd,
      default_text = opts.search,
      prompt_title = opts.title or opts.prompt_title,
    })
  end
end

function M.find_zettel_note()
  find_files({ cwd = paths.zettel_root, title = "Zettelkasten files" })
end

function M.find_in_note()
  find_files({ cwd = paths.in_root, title = "In files" })
end

function M.grep_zettel()
  grep({ cwd = paths.zettel_root, title = "Grep zettelkasten" })
end

function M.grep_in()
  grep({ cwd = paths.in_root, title = "Grep in" })
end

function M.search_word()
  if not fs.is_directory(paths.zettel_root) then
    vim.notify("Content search root does not exist: " .. paths.zettel_root, vim.log.levels.WARN)
    return
  end

  local word = vim.fn.expand("<cword>")
  local picker = snacks_picker()
  if picker then
    if vim.fn.executable("rg") ~= 1 then
      vim.notify("Content search needs ripgrep: install rg for live grep.", vim.log.levels.WARN)
      return
    end
    picker.grep_word(config.picker_defaults({ cwd = paths.zettel_root, search = word }))
  else
    telescope().grep_string({ cwd = paths.zettel_root, search = word })
  end
end

function M.find_headings()
  grep({ cwd = paths.zettel_root, search = "^# ", title = "Headings" })
end

function M.find_scope_file()
  find_files({ cwd = context.current_scope_dir(), title = "Scope files" })
end

function M.find_folder_files(dir)
  find_files({ cwd = dir, title = "Files in " .. vim.fn.fnamemodify(dir, ":t") })
end

function M.find_recent_files()
  local picker = snacks_picker()
  if picker then
    local opts = require("upsc_notes.recent_views").picker_options()
    if opts then
      picker.pick(config.picker_defaults(opts))
    else
      picker.recent({ title = "Recent files" })
    end
  else
    telescope().oldfiles({ prompt_title = "Recent files" })
  end
end

function M.find_recent_scope_files()
  local cwd = context.current_scope_dir()
  local picker = snacks_picker()
  if picker then
    picker.recent(config.picker_defaults({ title = "Recent files in current scope", filter = { cwd = cwd } }))
  else
    telescope().oldfiles({ cwd = cwd, prompt_title = "Recent files in current scope" })
  end
end

function M.grep_scope()
  grep({ cwd = context.current_scope_dir(), title = "Grep current scope" })
end

function M.grep_folder(dir)
  grep({ cwd = dir, title = "Grep " .. vim.fn.fnamemodify(dir, ":t") })
end

function M.read_folder(dir)
  require("upsc_notes.folder_reader").open(dir)
end

function M.read_focused_folder()
  local manager = package.loaded["neo-tree.sources.manager"]
  if manager then
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      local ok, state = pcall(manager.get_state_for_window, win)
      if ok and state and state.name == "filesystem" and fs.is_directory(state.path) then
        M.read_folder(state.path)
        return
      end
    end

    local ok, state = pcall(manager.get_state, "filesystem")
    if ok and state and fs.is_directory(state.path) then
      M.read_folder(state.path)
      return
    end
  end
  vim.notify("Focus a folder in the filesystem explorer first", vim.log.levels.WARN)
end

function M.resume_picker()
  local picker = snacks_picker()
  if picker then
    picker.resume()
  else
    telescope().resume()
  end
end

function M.find_buffers()
  local picker = snacks_picker()
  if picker then
    picker.buffers()
  else
    telescope().buffers()
  end
end

function M.find_commands()
  local picker = snacks_picker()
  if picker then
    picker.commands()
  else
    telescope().commands()
  end
end

function M.find_keymaps()
  local picker = snacks_picker()
  if picker then
    picker.keymaps()
  else
    telescope().keymaps()
  end
end

function M.find_marks()
  local picker = snacks_picker()
  if picker then
    picker.marks()
  else
    telescope().marks()
  end
end

function M.find_undo()
  local picker = snacks_picker()
  if picker and picker.undo then
    picker.undo()
  else
    vim.notify("Undo picker is not available", vim.log.levels.WARN)
  end
end

return M
