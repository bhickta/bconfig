vim.g.mapleader = " "
vim.g.maplocalleader = " "

local vault_root = "/home/bhickta/development/upsc"
local zettel_root = vault_root .. "/zettelkasten"
local home_note = vault_root .. "/Home.md"

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = ""
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.termguicolors = true
vim.opt.updatetime = 250
vim.opt.timeoutlen = 400
vim.opt.undofile = true
vim.opt.grepprg = "rg --vimgrep --smart-case"

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  {
    "nvim-lua/plenary.nvim",
  },
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local telescope = require("telescope")
      telescope.setup({
        defaults = {
          path_display = { "smart" },
          mappings = {
            i = {
              ["<C-j>"] = "move_selection_next",
              ["<C-k>"] = "move_selection_previous",
            },
          },
        },
        pickers = {
          find_files = {
            hidden = true,
            no_ignore = false,
          },
        },
      })
    end,
  },
  {
    "epwalsh/obsidian.nvim",
    version = "*",
    ft = "markdown",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
    opts = {
      workspaces = {
        {
          name = "upsc",
          path = vault_root,
        },
      },
      notes_subdir = "inbox",
      new_notes_location = "notes_subdir",
      completion = {
        nvim_cmp = false,
      },
      mappings = {
        ["gf"] = {
          action = function()
            return require("obsidian").util.gf_passthrough()
          end,
          opts = { noremap = false, expr = true, buffer = true },
        },
      },
      picker = {
        name = "telescope.nvim",
      },
      disable_frontmatter = true,
    },
  },
  {
    "preservim/vim-markdown",
    ft = "markdown",
    init = function()
      vim.g.vim_markdown_folding_disabled = 1
      vim.g.vim_markdown_conceal = 0
      vim.g.vim_markdown_conceal_code_blocks = 0
      vim.g.vim_markdown_frontmatter = 1
    end,
  },
})

local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { silent = true, noremap = true, desc = desc })
end

local function telescope_builtin()
  return require("telescope.builtin")
end

local function open_parent_waypoint()
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
      vim.cmd("edit " .. vim.fn.fnameescape(candidate))
      return
    end
  end

  vim.notify("No parent Waypoint note found in " .. dir, vim.log.levels.WARN)
end

local function jump_to_next_wikilink()
  vim.fn.search("\\[\\[[^]]\\+\\]\\]", "W")
end

local function jump_to_prev_wikilink()
  vim.fn.search("\\[\\[[^]]\\+\\]\\]", "bW")
end

local function set_read_mode()
  vim.opt_local.readonly = true
  vim.opt_local.modifiable = false
  vim.opt_local.conceallevel = 1
  vim.notify("Read mode: buffer locked", vim.log.levels.INFO)
end

local function set_edit_mode()
  vim.opt_local.modifiable = true
  vim.opt_local.readonly = false
  vim.notify("Edit mode: buffer unlocked", vim.log.levels.INFO)
end

local function toggle_read_edit_mode()
  if vim.bo.modifiable then
    set_read_mode()
  else
    set_edit_mode()
  end
end

map("n", "<leader>ff", function()
  telescope_builtin().find_files({ cwd = vault_root, prompt_title = "Vault files" })
end, "Find vault file")

map("n", "<leader>fz", function()
  telescope_builtin().find_files({ cwd = zettel_root, prompt_title = "Zettelkasten files" })
end, "Find zettelkasten note")

map("n", "<leader>fg", function()
  telescope_builtin().live_grep({ cwd = zettel_root, prompt_title = "Grep zettelkasten" })
end, "Grep zettelkasten")

map("n", "<leader>fG", function()
  telescope_builtin().live_grep({ cwd = vault_root, prompt_title = "Grep full vault" })
end, "Grep full vault")

map("n", "<leader>fw", function()
  telescope_builtin().grep_string({ cwd = zettel_root, search = vim.fn.expand("<cword>") })
end, "Search word in zettelkasten")

map("n", "<leader>fh", function()
  telescope_builtin().live_grep({ cwd = zettel_root, default_text = "^# ", prompt_title = "Headings" })
end, "Find headings")

map("n", "<leader>ww", function()
  telescope_builtin().grep_string({ cwd = zettel_root, search = "%% Begin Waypoint %%" })
end, "Find Waypoint indexes")

map("n", "<leader>fb", "<cmd>ObsidianBacklinks<cr>", "Current note backlinks")
map("n", "<leader>fl", "<cmd>ObsidianLinks<cr>", "Current note links")
map("n", "<leader>fo", "<cmd>ObsidianQuickSwitch<cr>", "Obsidian quick switch")
map("n", "<leader>fs", "<cmd>ObsidianSearch<cr>", "Obsidian search")
map("n", "<leader>fn", "<cmd>ObsidianNew<cr>", "New note in inbox")
map("n", "gd", "<cmd>ObsidianFollowLink<cr>", "Follow Obsidian link")
map("n", "<leader>wp", open_parent_waypoint, "Open parent Waypoint")
map("n", "]w", jump_to_next_wikilink, "Next wiki link")
map("n", "[w", jump_to_prev_wikilink, "Previous wiki link")
map("n", "<leader>rr", toggle_read_edit_mode, "Toggle read/edit mode")
map("n", "<leader>re", set_edit_mode, "Edit mode")
map("n", "<leader>ro", set_read_mode, "Read-only mode")
map("n", "<leader>ov", function()
  vim.cmd("edit " .. vim.fn.fnameescape(vault_root .. "/zettelkasten"))
end, "Open zettelkasten directory")
map("n", "<leader>oh", function()
  vim.cmd("edit " .. vim.fn.fnameescape(home_note))
end, "Open vault home")

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.breakindent = true
    vim.opt_local.conceallevel = 1
    vim.opt_local.textwidth = 0
    vim.opt_local.spell = false
    vim.keymap.set("n", "<cr>", "<cmd>ObsidianFollowLink<cr>", {
      buffer = true,
      silent = true,
      desc = "Follow Obsidian link",
    })
    vim.keymap.set("n", "<bs>", "<c-o>", {
      buffer = true,
      silent = true,
      desc = "Jump back",
    })
  end,
})

vim.api.nvim_create_user_command("Vault", function()
  vim.cmd("cd " .. vim.fn.fnameescape(vault_root))
  vim.cmd("edit " .. vim.fn.fnameescape(home_note))
end, {})

vim.api.nvim_create_user_command("Zettel", function()
  telescope_builtin().find_files({ cwd = zettel_root, prompt_title = "Zettelkasten files" })
end, {})

vim.api.nvim_create_user_command("Zgrep", function(opts)
  telescope_builtin().live_grep({
    cwd = zettel_root,
    default_text = opts.args,
    prompt_title = "Grep zettelkasten",
  })
end, { nargs = "*" })

vim.api.nvim_create_user_command("Waypoints", function()
  telescope_builtin().grep_string({ cwd = zettel_root, search = "%% Begin Waypoint %%" })
end, {})

vim.api.nvim_create_user_command("Zparent", open_parent_waypoint, {})
vim.api.nvim_create_user_command("ReadMode", set_read_mode, {})
vim.api.nvim_create_user_command("EditMode", set_edit_mode, {})
vim.api.nvim_create_user_command("ToggleReadEdit", toggle_read_edit_mode, {})
