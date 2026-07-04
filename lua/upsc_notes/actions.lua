local paths = require("upsc_notes.paths")

local M = {}

local function telescope()
  return require("telescope.builtin")
end

local function edit(path)
  vim.cmd("edit " .. vim.fn.fnameescape(path))
end

local function center_line(text, width)
  local padding = math.max(math.floor((width - #text) / 2), 0)
  return string.rep(" ", padding) .. text
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
  vim.cmd("Neotree filesystem reveal left dir=" .. vim.fn.fnameescape(paths.vault_root))
end

function M.open_zettel_tree()
  vim.cmd("Neotree filesystem reveal left dir=" .. vim.fn.fnameescape(paths.zettel_root))
end

function M.reveal_current_note()
  vim.cmd("Neotree filesystem reveal left")
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

  local buf = vim.api.nvim_create_buf(false, true)
  local width = vim.o.columns
  local lines = {
    "",
    " _   _ ____  ____   ____ ",
    "| | | |  _ \\|  _ \\ / ___|",
    "| | | | |_) | |_) | |    ",
    "| |_| |  __/|  __/| |___ ",
    " \\___/|_|   |_|    \\____|",
    "",
    "Obsidian vault, Vim keys, Waypoint reading",
    "",
    "h  Open vault Home.md",
    "t  Open zettelkasten folder tree",
    "w  Find Waypoint indexes",
    "z  Find zettelkasten note",
    "g  Search zettelkasten text",
    "c  Reveal current note in tree",
    "e  Ethics index",
    "p  Polity index",
    "m  Mapping shortcuts",
    "r  Open Home.md in read mode",
    "",
    "Enter/gd follow links inside notes    Backspace jump back",
    "Space rr toggles read/edit            Space oh returns Home.md",
    "",
    "q  Close dashboard",
  }

  for i, line in ipairs(lines) do
    lines[i] = center_line(line, width)
  end

  vim.api.nvim_set_current_buf(buf)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype = "upsc_dashboard"
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = false
  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.signcolumn = "no"
  vim.wo.foldcolumn = "0"
  vim.wo.cursorline = false

  local function dash_map(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, { buffer = buf, silent = true, noremap = true, desc = desc })
  end

  dash_map("h", M.open_home, "Open vault home")
  dash_map("t", M.open_zettel_tree, "Open zettelkasten tree")
  dash_map("w", M.find_waypoints, "Find Waypoint indexes")
  dash_map("z", M.find_zettel_note, "Find zettelkasten note")
  dash_map("g", M.grep_zettel, "Search zettelkasten")
  dash_map("c", M.reveal_current_note, "Reveal current note")
  dash_map("e", M.open_ethics, "Open Ethics")
  dash_map("p", M.open_polity, "Open Polity")
  dash_map("m", M.open_mapping_section, "Open Mapping section")
  dash_map("r", M.open_home_read_only, "Open home read-only")
  dash_map("q", "<cmd>bd<cr>", "Close dashboard")
end

return M
