local paths = require("upsc_notes.paths")

return {
  {
    "nvim-lua/plenary.nvim",
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1100,
    config = function()
      require("catppuccin").setup({
        flavour = "mocha",
        transparent_background = false,
        show_end_of_buffer = false,
        term_colors = true,
        dim_inactive = {
          enabled = false,
        },
        integrations = {
          native_lsp = false,
          telescope = true,
          which_key = true,
          markdown = true,
          neotree = true,
          snacks = true,
        },
      })
      vim.cmd.colorscheme("catppuccin-mocha")
      require("upsc_notes.ui").setup()
    end,
  },
  {
    "goolord/alpha-nvim",
    cmd = "Alpha",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local alpha = require("alpha")
      local dashboard = require("alpha.themes.dashboard")

      dashboard.section.header.val = {
        "                                                       ",
        "  ██╗   ██╗██████╗ ███████╗ ██████╗                   ",
        "  ██║   ██║██╔══██╗██╔════╝██╔════╝                   ",
        "  ██║   ██║██████╔╝███████╗██║                        ",
        "  ██║   ██║██╔═══╝ ╚════██║██║                        ",
        "  ╚██████╔╝██║     ███████║╚██████╗                   ",
        "   ╚═════╝ ╚═╝     ╚══════╝ ╚═════╝                   ",
        "                                                       ",
        "          Zettelkasten  •  Waypoints  •  Vim          ",
        "                                                       ",
      }

      dashboard.section.buttons.val = {
        dashboard.button("t", "  Zettelkasten tree", "<cmd>Ztree<CR>"),
        dashboard.button("v", "󰉋  Vault tree", "<cmd>VaultTree<CR>"),
        dashboard.button("w", "󰈙  Waypoint indexes", "<cmd>Waypoints<CR>"),
        dashboard.button("z", "󰱼  Find zettelkasten note", "<cmd>Zettel<CR>"),
        dashboard.button("g", "  Search zettelkasten text", "<cmd>Zgrep<CR>"),
        dashboard.button("s", "󰱼  Find in current scope", "<cmd>ScopeFiles<CR>"),
        dashboard.button("/", "󰱽  Search current scope", "<cmd>ScopeGrep<CR>"),
        dashboard.button("r", "󱋡  Recent vault notes", "<cmd>RecentNotes<CR>"),
        dashboard.button("f", "󰉋  Focus tree on current scope", "<cmd>FocusTree<CR>"),
        dashboard.button("u", "󰁌  Unfocus tree to zettelkasten", "<cmd>UnfocusTree<CR>"),
        dashboard.button("p", "󰊄  Polity index", "<cmd>Polity<CR>"),
        dashboard.button("e", "󰯂  Ethics index", "<cmd>Ethics<CR>"),
        dashboard.button("q", "󰅚  Quit", "<cmd>qa<CR>"),
      }

      dashboard.section.footer.val = {
        "",
        "Space f z files   Space f g text   Space f / scope   Space rr read/edit",
      }

      dashboard.section.header.opts.hl = "UpscDashboardHeader"
      dashboard.section.buttons.opts.hl = "UpscDashboardButton"
      dashboard.section.footer.opts.hl = "UpscDashboardFooter"
      dashboard.opts.opts.noautocmd = true

      alpha.setup(dashboard.opts)
    end,
  },
  {
    "folke/snacks.nvim",
    commit = "3a8ecf591263e4706d9b3a45da590df914ea5505",
    lazy = false,
    priority = 1000,
    opts = {
      input = {},
      picker = {
        ui_select = true,
        layout = {
          preset = "ivy",
        },
      },
    },
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "modern",
      delay = 250,
      win = {
        border = "rounded",
      },
    },
    config = function(_, opts)
      local wk = require("which-key")
      wk.setup(opts)
      wk.add({
        { "<leader>f", group = "find/search" },
        { "<leader>t", group = "tree" },
        { "<leader>w", group = "waypoint" },
        { "<leader>r", group = "read/edit" },
        { "<leader>o", group = "open" },
      })
    end,
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
