local paths = require("upsc_notes.paths")

local M = {}

local function telescope()
  return require("telescope.builtin")
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

function M.find_vault_file()
  telescope().find_files({ cwd = paths.vault_root, prompt_title = "Vault files" })
end

function M.find_zettel_note()
  telescope().find_files({ cwd = paths.zettel_root, prompt_title = "Zettelkasten files" })
end

function M.grep_zettel()
  telescope().live_grep({ cwd = paths.zettel_root, prompt_title = "Grep zettelkasten" })
end

function M.grep_vault()
  telescope().live_grep({ cwd = paths.vault_root, prompt_title = "Grep full vault" })
end

function M.search_word()
  telescope().grep_string({ cwd = paths.zettel_root, search = vim.fn.expand("<cword>") })
end

function M.find_headings()
  telescope().live_grep({ cwd = paths.zettel_root, default_text = "^# ", prompt_title = "Headings" })
end

function M.find_waypoints()
  telescope().grep_string({ cwd = paths.zettel_root, search = "%% Begin Waypoint %%" })
end

function M.open_vault_tree()
  open_tree_at(paths.vault_root)
end

function M.open_zettel_tree()
  open_tree_at(paths.zettel_root)
end

function M.open_ajay_tree()
  open_tree_at(paths.ajay_root)
end

function M.open_ajay_index()
  edit(paths.ajay_index)
end

function M.reveal_current_note()
  vim.cmd("Neotree filesystem reveal left")
end

function M.focus_current_study_tree()
  local current = vim.api.nvim_buf_get_name(0)
  if current == "" then
    M.open_zettel_tree()
    return
  end

  local dir = vim.fn.fnamemodify(current, ":h")

  if current:find(paths.ajay_root, 1, true) == 1 then
    open_tree_at(paths.ajay_root)
    return
  end

  if current:find(paths.inbox_root, 1, true) == 1 then
    local relative = current:sub(#paths.inbox_root + 2)
    local top = relative:match("^([^/]+)")
    if top then
      open_tree_at(paths.inbox_root .. "/" .. top)
      return
    end
  end

  if current:find(paths.zettel_root, 1, true) == 1 then
    local relative = current:sub(#paths.zettel_root + 2)
    local subject = relative:match("^([^/]+)")
    local chapter = relative:match("^[^/]+/([^/]+)")
    if subject and chapter then
      open_tree_at(paths.zettel_root .. "/" .. subject .. "/" .. chapter)
      return
    elseif subject then
      open_tree_at(paths.zettel_root .. "/" .. subject)
      return
    end
  end

  open_tree_at(dir)
end

function M.open_home()
  edit(paths.home_note)
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

function M.open_mapping_section()
  M.open_home()
  vim.fn.search("^## Mapping", "W")
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

function M.open_home_read_only()
  M.open_home()
  M.set_read_mode()
end

function M.open_dashboard()
  vim.cmd("cd " .. vim.fn.fnameescape(paths.vault_root))
  vim.cmd("Alpha")
end

return M
