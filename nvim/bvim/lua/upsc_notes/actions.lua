local config = require("upsc_notes.config")
local paths = require("upsc_notes.paths")

local M = {}

local function telescope()
  return require("telescope.builtin")
end

local function snacks_picker()
  local ok, snacks = pcall(require, "snacks")
  if ok and snacks.picker then
    return snacks.picker
  end
end

local function edit(path)
  vim.cmd("edit " .. vim.fn.fnameescape(path))
end

local function is_dir(path)
  local stat = vim.loop.fs_stat(path)
  return stat and stat.type == "directory"
end

local function is_file(path)
  local stat = vim.loop.fs_stat(path)
  return stat and stat.type == "file"
end

local function in_vault(path)
  return path ~= "" and path:find(paths.vault_root, 1, true) == 1
end

local function open_tree_at(path, reveal_file)
  if not is_dir(path) then
    vim.notify("Tree root does not exist: " .. path, vim.log.levels.WARN)
    return
  end

  require("neo-tree.command").execute({
    action = "focus",
    source = "filesystem",
    position = "left",
    dir = path,
    reveal_file = reveal_file,
    reveal_force_cwd = reveal_file ~= nil,
  })
end

local function picker_defaults(opts)
  return config.picker_defaults(opts)
end

local function file_command()
  if vim.fn.executable("rg") == 1 then
    return "rg"
  end
  if vim.fn.executable("fd") == 1 then
    return "fd"
  end
  if vim.fn.executable("fdfind") == 1 then
    return "fdfind"
  end
  return "find"
end

local function active_note_path()
  local current = vim.api.nvim_buf_get_name(0)
  if in_vault(current) and (is_file(current) or is_dir(current)) then
    return current
  end

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype ~= "neo-tree" then
      local name = vim.api.nvim_buf_get_name(buf)
      if in_vault(name) and (is_file(name) or is_dir(name)) then
        return name
      end
    end
  end

  local alternate = vim.fn.bufname("#")
  if in_vault(alternate) and (is_file(alternate) or is_dir(alternate)) then
    return alternate
  end

  return ""
end

local function current_scope_dir()
  local current = active_note_path()
  if current == "" then
    return paths.zettel_root
  end
  if is_dir(current) then
    return current
  end
  return vim.fn.fnamemodify(current, ":h")
end

local function active_root_dir()
  local current = active_note_path()
  if current ~= "" and current:find(paths.in_root, 1, true) == 1 then
    return paths.in_root
  end
  return paths.zettel_root
end

local function is_tree_window(win)
  local buf = vim.api.nvim_win_get_buf(win)
  return vim.bo[buf].filetype == "neo-tree"
end

local function find_files(opts)
  if not is_dir(opts.cwd) then
    vim.notify("File search root does not exist: " .. opts.cwd, vim.log.levels.WARN)
    return
  end

  opts.hidden = true
  opts.ignored = false
  opts.cmd = opts.cmd or file_command()
  opts = picker_defaults(opts)

  local picker = snacks_picker()
  if picker then
    picker.files(opts)
    return
  end

  telescope().find_files({ cwd = opts.cwd, prompt_title = opts.title or opts.prompt_title })
end

local function grep(opts)
  if not is_dir(opts.cwd) then
    vim.notify("Content search root does not exist: " .. opts.cwd, vim.log.levels.WARN)
    return
  end

  if vim.fn.executable("rg") ~= 1 then
    vim.notify("Content search needs ripgrep: install rg for live grep.", vim.log.levels.WARN)
    return
  end

  opts.hidden = true
  opts.ignored = false
  opts = picker_defaults(opts)

  local picker = snacks_picker()
  if picker then
    picker.grep(opts)
    return
  end

  telescope().live_grep({
    cwd = opts.cwd,
    default_text = opts.search,
    prompt_title = opts.title or opts.prompt_title,
  })
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
  if not is_dir(paths.zettel_root) then
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
    picker.grep_word(picker_defaults({ cwd = paths.zettel_root, search = word }))
    return
  end

  telescope().grep_string({ cwd = paths.zettel_root, search = word })
end

function M.find_headings()
  grep({ cwd = paths.zettel_root, search = "^# ", title = "Headings" })
end

function M.find_scope_file()
  find_files({ cwd = current_scope_dir(), title = "Scope files" })
end

function M.grep_scope()
  grep({ cwd = current_scope_dir(), title = "Grep current scope" })
end

function M.resume_picker()
  local picker = snacks_picker()
  if picker then
    picker.resume()
    return
  end

  telescope().resume()
end

function M.find_buffers()
  local picker = snacks_picker()
  if picker then
    picker.buffers()
    return
  end

  telescope().buffers()
end

function M.find_commands()
  local picker = snacks_picker()
  if picker then
    picker.commands()
    return
  end

  telescope().commands()
end

function M.find_keymaps()
  local picker = snacks_picker()
  if picker then
    picker.keymaps()
    return
  end

  telescope().keymaps()
end

function M.find_marks()
  local picker = snacks_picker()
  if picker then
    picker.marks()
    return
  end

  telescope().marks()
end

function M.find_undo()
  local picker = snacks_picker()
  if picker and picker.undo then
    picker.undo()
    return
  end

  vim.notify("Undo picker is not available", vim.log.levels.WARN)
end

function M.open_vault_tree()
  open_tree_at(paths.vault_root)
end

function M.open_zettel_tree()
  open_tree_at(paths.zettel_root)
end

function M.open_in_tree()
  open_tree_at(paths.in_root)
end

function M.reveal_current_note()
  local current = active_note_path()
  if current == "" then
    M.open_zettel_tree()
    return
  end

  local dir = is_dir(current) and current or vim.fn.fnamemodify(current, ":h")
  local reveal_file = is_file(current) and current or nil
  open_tree_at(dir, reveal_file)
end

function M.focus_tree()
  local current = active_note_path()
  local dir = current_scope_dir()
  local reveal_file = is_file(current) and current or nil
  open_tree_at(dir, reveal_file)
end

function M.unfocus_tree()
  open_tree_at(active_root_dir())
end

function M.open_zettelkasten_dir()
  edit(paths.zettel_root)
end

function M.open_in_dir()
  edit(paths.in_root)
end

function M.toggle_tree()
  local root = active_root_dir()
  require("neo-tree.command").execute({
    action = "focus",
    source = "filesystem",
    position = "left",
    dir = root,
    toggle = true,
  })
end

function M.toggle_tree_focus()
  local current_win = vim.api.nvim_get_current_win()
  if is_tree_window(current_win) then
    vim.cmd("wincmd p")
    return
  end

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if is_tree_window(win) then
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
      dir = active_root_dir(),
    })
  end
end

function M.jump_to_next_wikilink()
  vim.fn.search("\\[\\[[^]]\\+\\]\\]", "W")
end

function M.jump_to_prev_wikilink()
  vim.fn.search("\\[\\[[^]]\\+\\]\\]", "bW")
end

local function set_reading_window(enabled)
  vim.wo.number = true
  vim.wo.relativenumber = not enabled
  vim.wo.signcolumn = enabled and "no" or "yes"
  vim.wo.foldcolumn = "0"
  vim.wo.cursorline = not enabled
  vim.wo.list = false
end

local function set_markdown_reading_buffer(enabled)
  config.apply_markdown_reading_options(enabled)
end

function M.set_read_mode()
  vim.opt_local.readonly = true
  vim.opt_local.modifiable = false
  set_markdown_reading_buffer(true)
  set_reading_window(true)
  vim.notify("Read mode: buffer locked", vim.log.levels.INFO)
end

function M.set_edit_mode()
  vim.opt_local.modifiable = true
  vim.opt_local.readonly = false
  set_markdown_reading_buffer(false)
  set_reading_window(false)
  vim.notify("Edit mode: buffer unlocked", vim.log.levels.INFO)
end

function M.toggle_read_edit_mode()
  if vim.bo.modifiable then
    M.set_read_mode()
  else
    M.set_edit_mode()
  end
end

function M.enable_study_mode()
  vim.b.upsc_study_mode = true
  set_markdown_reading_buffer(true)
  set_reading_window(true)
  vim.notify("Study mode: clean reading area", vim.log.levels.INFO)
end

function M.disable_study_mode()
  vim.b.upsc_study_mode = false
  set_markdown_reading_buffer(false)
  set_reading_window(false)
  vim.notify("Study mode off", vim.log.levels.INFO)
end

function M.toggle_study_mode()
  if vim.b.upsc_study_mode then
    M.disable_study_mode()
  else
    M.enable_study_mode()
  end
end

function M.toggle_markdown_render()
  local ok, render = pcall(require, "render-markdown")
  if not ok then
    vim.notify("render-markdown.nvim is not available", vim.log.levels.WARN)
    return
  end

  render.toggle()
end

function M.toggle_zen()
  local ok, snacks = pcall(require, "snacks")
  if ok and snacks.zen then
    snacks.zen()
    return
  end

  vim.notify("Snacks zen is not available", vim.log.levels.WARN)
end

function M.dismiss_notifications()
  local ok, notifier = pcall(require, "snacks.notifier")
  if ok then
    notifier.hide()
  end
end

function M.open_dashboard()
  vim.cmd("cd " .. vim.fn.fnameescape(paths.vault_root))
  vim.cmd("Alpha")
end

return M
