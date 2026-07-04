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
    lazy = false,
    priority = 1000,
    opts = {
      input = {},
      picker = {
        ui_select = true,
        matcher = {
          fuzzy = true,
          smartcase = true,
          ignorecase = true,
          sort_empty = false,
          filename_bonus = true,
          file_pos = true,
          cwd_bonus = true,
          frecency = false,
          history_bonus = false,
        },
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
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    opts = {
      install_dir = vim.fn.stdpath("data") .. "/site",
      ensure_installed = { "markdown", "markdown_inline", "yaml", "html", "lua", "vim", "vimdoc" },
    },
    config = function(_, opts)
      local treesitter = require("nvim-treesitter")
      treesitter.setup({
        install_dir = opts.install_dir,
      })

      local installed = treesitter.get_installed()
      local missing = vim.tbl_filter(function(parser)
        return not vim.tbl_contains(installed, parser)
      end, opts.ensure_installed)

      if #missing > 0 then
        treesitter.install(missing):wait(300000)
      end

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("UpscNotesTreesitter", { clear = true }),
        pattern = { "markdown", "yaml", "html", "lua", "vim", "vimdoc" },
        callback = function()
          pcall(vim.treesitter.start)
        end,
      })
    end,
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = "markdown",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      enabled = true,
      preset = "obsidian",
      render_modes = { "n", "c", "t" },
      max_file_size = 8.0,
      debounce = 80,
      file_types = { "markdown" },
      completions = {
        lsp = {
          enabled = false,
        },
      },
      heading = {
        enabled = true,
        sign = false,
        width = "full",
        right_pad = 1,
        icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
        backgrounds = {
          "RenderMarkdownH1Bg",
          "RenderMarkdownH2Bg",
          "RenderMarkdownH3Bg",
          "RenderMarkdownH4Bg",
          "RenderMarkdownH5Bg",
          "RenderMarkdownH6Bg",
        },
        foregrounds = {
          "RenderMarkdownH1",
          "RenderMarkdownH2",
          "RenderMarkdownH3",
          "RenderMarkdownH4",
          "RenderMarkdownH5",
          "RenderMarkdownH6",
        },
      },
      code = {
        enabled = true,
        sign = false,
        style = "full",
        position = "left",
        language_pad = 1,
        left_pad = 1,
        right_pad = 1,
        min_width = 60,
        border = "thin",
      },
      bullet = {
        enabled = true,
        icons = { "•", "◦", "▪", "▫" },
      },
      checkbox = {
        enabled = true,
        unchecked = {
          icon = "󰄱 ",
        },
        checked = {
          icon = "󰱒 ",
        },
      },
      quote = {
        enabled = true,
        icon = "▌",
      },
      pipe_table = {
        enabled = true,
        preset = "round",
      },
      callout = {
        note = { raw = "[!NOTE]", rendered = "󰋽 Note", highlight = "RenderMarkdownInfo" },
        tip = { raw = "[!TIP]", rendered = "󰌶 Tip", highlight = "RenderMarkdownSuccess" },
        important = { raw = "[!IMPORTANT]", rendered = "󰅾 Important", highlight = "RenderMarkdownHint" },
        warning = { raw = "[!WARNING]", rendered = "󰀪 Warning", highlight = "RenderMarkdownWarn" },
        caution = { raw = "[!CAUTION]", rendered = "󰳦 Caution", highlight = "RenderMarkdownError" },
      },
      link = {
        enabled = true,
        image = "󰥶 ",
        email = "󰀓 ",
        hyperlink = "󰌹 ",
        wiki = {
          icon = "󰖟 ",
        },
      },
      win_options = {
        conceallevel = {
          default = 2,
          rendered = 3,
        },
        concealcursor = {
          default = "nc",
          rendered = "",
        },
      },
    },
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
    branch = "main",
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
}
