local M = {}

local function smart_split(method)
  return function()
    require("smart-splits")[method]()
  end
end

local function map(mode, lhs, rhs, desc, opts)
  return vim.tbl_extend("force", {
    mode = mode,
    lhs = lhs,
    rhs = rhs,
    desc = desc,
  }, opts or {})
end

local function command(cmd)
  return "<cmd>" .. cmd .. "<cr>"
end

function M.which_key_groups()
  return {
    { "<leader>f", group = "find/search" },
    { "<leader>m", group = "markdown/notes" },
    { "<leader>p", group = "plugins" },
    { "<leader>t", group = "tree" },
    { "<leader>r", group = "read/edit" },
    { "<leader>u", group = "ui" },
  }
end

function M.global(actions)
  return {
    map("n", "<leader>w", command("w"), "Save"),
    map("n", "<leader>q", command("confirm q"), "Quit window"),
    map("n", "<leader>Q", command("confirm qall"), "Quit Neovim"),
    map("n", "<leader>n", command("enew"), "New file"),
    map("n", "|", command("vsplit"), "Vertical split"),
    map("n", "\\", command("split"), "Horizontal split"),

    map("n", "<C-h>", smart_split("move_cursor_left"), "Move to left split"),
    map("n", "<C-j>", smart_split("move_cursor_down"), "Move to below split"),
    map("n", "<C-k>", smart_split("move_cursor_up"), "Move to above split"),
    map("n", "<C-l>", smart_split("move_cursor_right"), "Move to right split"),
    map("n", "<C-Up>", smart_split("resize_up"), "Resize split up"),
    map("n", "<C-Down>", smart_split("resize_down"), "Resize split down"),
    map("n", "<C-Left>", smart_split("resize_left"), "Resize split left"),
    map("n", "<C-Right>", smart_split("resize_right"), "Resize split right"),

    map("v", "<S-Tab>", "<gv", "Unindent line"),
    map("v", "<Tab>", ">gv", "Indent line"),

    map("n", "<leader>fz", actions.find_zettel_note, "Find zettelkasten note"),
    map("n", "<leader>fi", actions.find_in_note, "Find in note"),
    map("n", "<leader>fg", actions.grep_zettel, "Grep zettelkasten"),
    map("n", "<leader>fI", actions.grep_in, "Grep in"),
    map("n", "<leader>f/", actions.grep_scope, "Grep current scope"),
    map("n", "<leader>fS", actions.find_scope_file, "Find file in current scope"),
    map("n", "<leader>fR", actions.resume_picker, "Resume last picker"),
    map("n", "<leader>fw", actions.search_word, "Search word in zettelkasten"),
    map("n", "<leader>f'", actions.find_marks, "Find marks"),
    map("n", "<leader>fb", actions.find_buffers, "Find buffers"),
    map("n", "<leader>fC", actions.find_commands, "Find commands"),
    map("n", "<leader>fk", actions.find_keymaps, "Find keymaps"),
    map("n", "<leader>fu", actions.find_undo, "Find undo history"),

    map("n", "<leader>tz", actions.open_zettel_tree, "Zettelkasten tree", { tree = true }),
    map("n", "<leader>ti", actions.open_in_tree, "In tree", { tree = true }),
    map("n", "<leader>tt", actions.toggle_tree, "Toggle tree", { tree = true }),
    map("n", "<leader>te", actions.toggle_tree_focus, "Editor/tree focus", { tree = true }),
    map("n", "<leader>tc", actions.reveal_current_note, "Reveal current note", { tree = true }),
    map("n", "<leader>tf", actions.focus_tree, "Focus tree here", { tree = true }),
    map("n", "<leader>tu", actions.unfocus_tree, "Unfocus tree", { tree = true }),
    map("n", "<leader>e", actions.toggle_tree, "Toggle Explorer", { tree = true }),
    map("n", "<leader>o", actions.focus_tree_panel, "Toggle Explorer Focus", { tree = true }),

    map("n", "<leader>mb", command("ObsidianBacklinks"), "Current note backlinks"),
    map("n", "<leader>ml", command("ObsidianLinks"), "Current note links"),
    map("n", "<leader>mo", command("ObsidianQuickSwitch"), "Obsidian quick switch"),
    map("n", "<leader>ms", command("ObsidianSearch"), "Obsidian search"),
    map("n", "<leader>mn", command("ObsidianNew"), "New note in in"),

    map("n", "gd", command("ObsidianFollowLink"), "Follow Obsidian link"),
    map("n", "]w", actions.jump_to_next_wikilink, "Next wiki link"),
    map("n", "[w", actions.jump_to_prev_wikilink, "Previous wiki link"),

    map("n", "<leader>rr", actions.toggle_read_edit_mode, "Toggle read/edit mode"),
    map("n", "<leader>re", actions.set_edit_mode, "Edit mode"),
    map("n", "<leader>ro", actions.set_read_mode, "Read-only mode"),
    map("n", "<leader>rs", actions.toggle_study_mode, "Toggle study mode"),
    map("n", "<leader>rm", actions.toggle_markdown_render, "Toggle markdown render"),

    map("n", "<leader>pi", command("Lazy install"), "Plugins install"),
    map("n", "<leader>ps", command("Lazy home"), "Plugins status"),
    map("n", "<leader>pS", command("Lazy sync"), "Plugins sync"),
    map("n", "<leader>pu", command("Lazy check"), "Plugins check updates"),
    map("n", "<leader>pU", command("Lazy update"), "Plugins update"),

    map("n", "<leader>uD", actions.dismiss_notifications, "Dismiss notifications"),
    map("n", "<leader>uZ", actions.toggle_zen, "Toggle zen mode"),

    map("n", "<leader>h", actions.open_dashboard, "Home dashboard"),
  }
end

function M.tree_buffer(actions)
  return vim.tbl_filter(function(shortcut)
    return shortcut.tree == true
  end, M.global(actions))
end

function M.dashboard_buttons(icons)
  local dashboard_icons = icons.dashboard
  return {
    { key = "t", label = dashboard_icons.zettel_tree .. "  Zettelkasten tree", command = "<cmd>Ztree<CR>" },
    { key = "i", label = dashboard_icons.in_tree .. "  In tree", command = "<cmd>InTree<CR>" },
    { key = "z", label = dashboard_icons.zettel_note .. "  Find zettelkasten note", command = "<cmd>Zettel<CR>" },
    { key = "n", label = dashboard_icons.in_note .. "  Find in note", command = "<cmd>In<CR>" },
    { key = "g", label = dashboard_icons.search .. "  Search zettelkasten text", command = "<cmd>Zgrep<CR>" },
    { key = "/", label = dashboard_icons.search .. "  Search in text", command = "<cmd>Ingrep<CR>" },
    { key = "q", label = dashboard_icons.quit .. "  Quit", command = "<cmd>qa<CR>" },
  }
end

function M.dashboard_footer()
  return "Space f z zettel   Space f i in   Space t z/t i tree   Space rr read/edit"
end

return M
