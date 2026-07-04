local paths = require("upsc_notes.paths")

return {
  {
    "nvim-lua/plenary.nvim",
  },
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("telescope").setup({
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
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    cmd = "Neotree",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      close_if_last_window = false,
      popup_border_style = "rounded",
      sources = { "filesystem", "buffers" },
      source_selector = {
        winbar = true,
        content_layout = "center",
      },
      default_component_configs = {
        indent = {
          padding = 0,
          with_expanders = true,
          expander_collapsed = "+",
          expander_expanded = "-",
        },
        icon = {
          folder_closed = "+",
          folder_open = "-",
          folder_empty = ".",
          default = " ",
        },
        git_status = {
          symbols = {
            added = "A",
            deleted = "D",
            modified = "M",
            renamed = "R",
            untracked = "?",
            ignored = "I",
            unstaged = "U",
            staged = "S",
            conflict = "!",
          },
        },
      },
      filesystem = {
        bind_to_cwd = false,
        follow_current_file = { enabled = true },
        group_empty_dirs = false,
        hijack_netrw_behavior = "open_current",
        filtered_items = {
          visible = true,
          hide_dotfiles = false,
          hide_gitignored = true,
          hide_by_name = {
            ".git",
            ".smart-env",
            ".trash",
          },
        },
        use_libuv_file_watcher = true,
      },
      window = {
        width = 42,
        mappings = {
          ["<space>"] = "toggle_node",
          ["<cr>"] = "open",
          h = "close_node",
          l = "open",
          H = "navigate_up",
          P = "toggle_preview",
          s = "open_split",
          S = "open_vsplit",
        },
      },
    },
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
          path = paths.vault_root,
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
}
