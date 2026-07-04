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

local function open_tree_at(path)
  if not is_dir(path) then
    vim.notify("Tree root does not exist: " .. path, vim.log.levels.WARN)
    return
  end

  vim.cmd("Neotree filesystem reveal left dir=" .. vim.fn.fnameescape(path))
end

local function current_scope_dir()
  local current = vim.api.nvim_buf_get_name(0)
  if current == "" then
    return paths.zettel_root
  end

  local dir = vim.fn.fnamemodify(current, ":h")

  if current:find(paths.inbox_root, 1, true) == 1 then
    local relative = current:sub(#paths.inbox_root + 2)
    local top = relative:match("^([^/]+)")
    if top then
      return paths.inbox_root .. "/" .. top
    end
  end

  if current:find(paths.zettel_root, 1, true) == 1 then
    local relative = current:sub(#paths.zettel_root + 2)
    local subject = relative:match("^([^/]+)")
    local chapter = relative:match("^[^/]+/([^/]+)")
    if subject and chapter then
      return paths.zettel_root .. "/" .. subject .. "/" .. chapter
    elseif subject then
      return paths.zettel_root .. "/" .. subject
    end
  end

  return dir
end

local function find_files(opts)
  opts.hidden = true
  opts.ignored = false

  local picker = snacks_picker()
  if picker then
    picker.files(opts)
    return
  end

  telescope().find_files({ cwd = opts.cwd, prompt_title = opts.title or opts.prompt_title })
end

local function grep(opts)
  opts.hidden = true
  opts.ignored = false

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

function M.find_vault_file()
  find_files({ cwd = paths.vault_root, title = "Vault files" })
end

function M.find_zettel_note()
  find_files({ cwd = paths.zettel_root, title = "Zettelkasten files" })
end

function M.grep_zettel()
  grep({ cwd = paths.zettel_root, title = "Grep zettelkasten" })
end

function M.grep_vault()
  grep({ cwd = paths.vault_root, title = "Grep full vault" })
end

function M.search_word()
  local word = vim.fn.expand("<cword>")
  local picker = snacks_picker()
  if picker then
    picker.grep_word({ cwd = paths.zettel_root, search = word })
    return
  end

  telescope().grep_string({ cwd = paths.zettel_root, search = word })
end

function M.find_headings()
  grep({ cwd = paths.zettel_root, search = "^# ", title = "Headings" })
end

function M.find_waypoints()
  grep({ cwd = paths.zettel_root, search = "%% Begin Waypoint %%", title = "Waypoint indexes" })
end

function M.find_scope_file()
  find_files({ cwd = current_scope_dir(), title = "Scope files" })
end

function M.grep_scope()
  grep({ cwd = current_scope_dir(), title = "Grep current scope" })
end

function M.recent_notes()
  local picker = snacks_picker()
  if picker then
    picker.recent({ cwd = paths.vault_root, filter = { cwd = true } })
    return
  end

  telescope().oldfiles({ cwd = paths.vault_root, prompt_title = "Recent vault files" })
end

function M.resume_picker()
  local picker = snacks_picker()
  if picker then
    picker.resume()
    return
  end

  telescope().resume()
end

function M.open_vault_tree()
  open_tree_at(paths.vault_root)
end

function M.open_zettel_tree()
  open_tree_at(paths.zettel_root)
end

function M.reveal_current_note()
  vim.cmd("Neotree filesystem reveal left")
end

function M.focus_tree()
  open_tree_at(current_scope_dir())
end

function M.unfocus_tree()
  M.open_zettel_tree()
end

function M.open_zettelkasten_dir()
  edit(paths.zettel_root)
end

function M.open_ethics()
  edit(paths.ethics_index)
end

function M.open_polity()
  edit(paths.polity_index)
end

function M.open_parent_waypoint()
  local current = vim.api.nvim_buf_get_name(0)
  if current == "" then
    return
  end

  local dir = vim.fn.fnamemodify(current, ":h")
  local parent_name = vim.fn.fnamemodify(dir, ":t")
  local candidates = {
    dir .. "/" .. parent_name .. ".md",
    dir .. "/00_Index.md",
    dir .. "/00_Overview.md",
  }

  for _, candidate in ipairs(candidates) do
    if vim.fn.filereadable(candidate) == 1 then
      edit(candidate)
      return
    end
  end

  vim.notify("No parent Waypoint note found in " .. dir, vim.log.levels.WARN)
end

function M.jump_to_next_wikilink()
  vim.fn.search("\\[\\[[^]]\\+\\]\\]", "W")
end

function M.jump_to_prev_wikilink()
  vim.fn.search("\\[\\[[^]]\\+\\]\\]", "bW")
end

function M.set_read_mode()
  vim.opt_local.readonly = true
  vim.opt_local.modifiable = false
  vim.opt_local.conceallevel = 1
  vim.notify("Read mode: buffer locked", vim.log.levels.INFO)
end

function M.set_edit_mode()
  vim.opt_local.modifiable = true
  vim.opt_local.readonly = false
  vim.notify("Edit mode: buffer unlocked", vim.log.levels.INFO)
end

function M.toggle_read_edit_mode()
  if vim.bo.modifiable then
    M.set_read_mode()
  else
    M.set_edit_mode()
  end
end

function M.open_dashboard()
  vim.cmd("cd " .. vim.fn.fnameescape(paths.vault_root))
  vim.cmd("Alpha")
end

return M
