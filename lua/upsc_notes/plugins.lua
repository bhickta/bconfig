local config = require("upsc_notes.config")
local paths = require("upsc_notes.paths")
local shortcuts = require("upsc_notes.shortcuts")

local icons = {
  dashboard = {
    zettel_tree = "▣",
    in_tree = "□",
    zettel_note = "◇",
    in_note = "◆",
    search = "⌕",
    quit = "×",
  },
  markdown = {
    headings = { "# ", "## ", "### ", "#### ", "##### ", "###### " },
    unchecked = "☐ ",
    checked = "☑ ",
    note = "i",
    tip = "✓",
    important = "!",
    warning = "!",
    caution = "×",
    image = "img ",
    email = "@ ",
    hyperlink = "↗ ",
    wiki = "[[",
  },
  tree = {
    file = "File",
    buffers = "Bufs",
    git = "Git",
    collapsed = "▸",
    expanded = "▾",
    folder_closed = "▣",
    folder_open = "▾",
    folder_empty = "□",
    file_default = "•",
    modified = "●",
  },
  git = {
    added = "+",
    deleted = "-",
    modified = "~",
    renamed = "→",
    untracked = "?",
    ignored = "·",
    unstaged = "!",
    staged = "✓",
    conflict = "×",
  },
}

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
        "",
        "██╗   ██╗██████╗ ███████╗ ██████╗",
        "██║   ██║██╔══██╗██╔════╝██╔════╝",
        "██║   ██║██████╔╝███████╗██║     ",
        "██║   ██║██╔═══╝ ╚════██║██║     ",
        "╚██████╔╝██║     ███████║╚██████╗",
        " ╚═════╝ ╚═╝     ╚══════╝ ╚═════╝",
        "",
        "Zettelkasten  •  In  •  Vim",
        "",
      }

      dashboard.section.buttons.val = {
      }

      for _, shortcut in ipairs(shortcuts.dashboard_buttons(icons)) do
        table.insert(dashboard.section.buttons.val, dashboard.button(shortcut.key, shortcut.label, shortcut.command))
      end

      dashboard.section.footer.val = {
        "",
        shortcuts.dashboard_footer(),
      }

      dashboard.section.header.opts.hl = "UpscDashboardHeader"
      dashboard.section.header.opts.position = "center"
      dashboard.section.buttons.opts.hl = "UpscDashboardButton"
      dashboard.section.buttons.opts.position = "center"
      dashboard.section.footer.opts.hl = "UpscDashboardFooter"
      dashboard.section.footer.opts.position = "center"
      dashboard.opts.opts.noautocmd = true

      alpha.setup(dashboard.opts)
    end,
  },
  {
    "folke/snacks.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      bigfile = {},
      quickfile = {},
      input = {},
      notifier = {
        timeout = 3500,
      },
      indent = {
        indent = { char = "▏" },
        scope = { char = "▏" },
        animate = { enabled = false },
        filter = function(buf)
          return vim.bo[buf].buftype == "" and vim.g.snacks_indent ~= false and vim.b[buf].snacks_indent ~= false
        end,
      },
      scope = {
        filter = function(buf)
          return vim.bo[buf].buftype == "" and vim.g.snacks_scope ~= false and vim.b[buf].snacks_scope ~= false
        end,
      },
      words = {
        enabled = true,
        filter = function(buf)
          return vim.bo[buf].buftype == "" and vim.g.snacks_words ~= false and vim.b[buf].snacks_words ~= false
        end,
      },
      zen = {
        toggles = { dim = false, diagnostics = false, inlay_hints = false },
        on_open = function(win)
          vim.b[win.buf].snacks_indent_old = vim.b[win.buf].snacks_indent
          vim.b[win.buf].snacks_indent = false
        end,
        on_close = function(win)
          vim.b[win.buf].snacks_indent = vim.b[win.buf].snacks_indent_old
        end,
        win = {
          width = function()
            return math.min(120, math.floor(vim.o.columns * 0.75))
          end,
          height = 0.9,
          backdrop = {
            transparent = false,
            win = { wo = { winhighlight = "Normal:Normal" } },
          },
          wo = {
            number = false,
            relativenumber = false,
            signcolumn = "no",
            foldcolumn = "0",
            winbar = "",
            list = false,
          },
        },
      },
      picker = {
        ui_select = true,
        matcher = config.get().picker.matcher,
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
      wk.add(shortcuts.which_key_groups())
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
    "mrjones2014/smart-splits.nvim",
    event = "VeryLazy",
    opts = {
      ignored_filetypes = { "nofile", "quickfix", "qf", "prompt" },
      ignored_buftypes = { "nofile" },
    },
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
        icons = icons.markdown.headings,
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
          icon = icons.markdown.unchecked,
        },
        checked = {
          icon = icons.markdown.checked,
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
        note = { raw = "[!NOTE]", rendered = icons.markdown.note .. " Note", highlight = "RenderMarkdownInfo" },
        tip = { raw = "[!TIP]", rendered = icons.markdown.tip .. " Tip", highlight = "RenderMarkdownSuccess" },
        important = { raw = "[!IMPORTANT]", rendered = icons.markdown.important .. " Important", highlight = "RenderMarkdownHint" },
        warning = { raw = "[!WARNING]", rendered = icons.markdown.warning .. " Warning", highlight = "RenderMarkdownWarn" },
        caution = { raw = "[!CAUTION]", rendered = icons.markdown.caution .. " Caution", highlight = "RenderMarkdownError" },
      },
      link = {
        enabled = true,
        image = icons.markdown.image,
        email = icons.markdown.email,
        hyperlink = icons.markdown.hyperlink,
        wiki = {
          icon = icons.markdown.wiki,
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
    opts = function()
      local git_available = vim.fn.executable("git") == 1
      local sources = {
        { source = "filesystem", display_name = icons.tree.file },
        { source = "buffers", display_name = icons.tree.buffers },
      }

      if git_available then
        table.insert(sources, 3, { source = "git_status", display_name = icons.tree.git })
      end

      return {
        enable_git_status = git_available,
        auto_clean_after_session_restore = true,
        close_if_last_window = true,
        popup_border_style = "",
        sources = { "filesystem", "buffers", git_available and "git_status" or nil },
        source_selector = {
          winbar = true,
          content_layout = "center",
          sources = sources,
        },
        default_component_configs = {
          indent = {
            padding = 0,
            expander_collapsed = icons.tree.collapsed,
            expander_expanded = icons.tree.expanded,
          },
          icon = {
            folder_closed = icons.tree.folder_closed,
            folder_open = icons.tree.folder_open,
            folder_empty = icons.tree.folder_empty,
            folder_empty_open = icons.tree.folder_empty,
            default = icons.tree.file_default,
          },
          modified = {
            symbol = icons.tree.modified,
          },
          git_status = {
            symbols = {
              added = icons.git.added,
              deleted = icons.git.deleted,
              modified = icons.git.modified,
              renamed = icons.git.renamed,
              untracked = icons.git.untracked,
              ignored = icons.git.ignored,
              unstaged = icons.git.unstaged,
              staged = icons.git.staged,
              conflict = icons.git.conflict,
            },
          },
        },
        commands = {
          system_open = function(state)
            vim.ui.open(state.tree:get_node():get_id())
          end,
          parent_or_close = function(state)
            local node = state.tree:get_node()
            if node:has_children() and node:is_expanded() then
              state.commands.toggle_node(state)
            else
              require("neo-tree.ui.renderer").focus_node(state, node:get_parent_id())
            end
          end,
          child_or_open = function(state)
            local node = state.tree:get_node()
            if node:has_children() then
              if not node:is_expanded() then
                state.commands.toggle_node(state)
              elseif node.type == "file" then
                state.commands.open(state)
              else
                require("neo-tree.ui.renderer").focus_node(state, node:get_child_ids()[1])
              end
            else
              state.commands.open(state)
            end
          end,
          copy_selector = function(state)
            local node = state.tree:get_node()
            local filepath = node:get_id()
            local filename = node.name
            local modify = vim.fn.fnamemodify
            local vals = {
              ["BASENAME"] = modify(filename, ":r"),
              ["EXTENSION"] = modify(filename, ":e"),
              ["FILENAME"] = filename,
              ["PATH (CWD)"] = modify(filepath, ":."),
              ["PATH (HOME)"] = modify(filepath, ":~"),
              ["PATH"] = filepath,
              ["URI"] = vim.uri_from_fname(filepath),
            }
            local options = vim.tbl_filter(function(val)
              return vals[val] ~= ""
            end, vim.tbl_keys(vals))

            table.sort(options)
            vim.ui.select(options, {
              prompt = "Choose to copy to clipboard:",
              format_item = function(item)
                return ("%s: %s"):format(item, vals[item])
              end,
            }, function(choice)
              local result = vals[choice]
              if result then
                vim.fn.setreg("+", result)
                vim.notify(("Copied: `%s`"):format(result), vim.log.levels.INFO)
              end
            end)
          end,
        },
        filesystem = {
          bind_to_cwd = false,
          follow_current_file = { enabled = true },
          filtered_items = {
            visible = true,
            hide_dotfiles = false,
            hide_gitignored = git_available,
            hide_by_name = {
              ".git",
              ".smart-env",
              ".trash",
            },
          },
          group_empty_dirs = false,
          hijack_netrw_behavior = "open_current",
          use_libuv_file_watcher = vim.fn.has("win32") ~= 1,
        },
        window = {
          width = 30,
          mappings = {
            ["<S-CR>"] = "system_open",
            ["<space>"] = false,
            ["[b"] = "prev_source",
            ["]b"] = "next_source",
            O = "system_open",
            Y = "copy_selector",
            h = "parent_or_close",
            l = "child_or_open",
          },
          fuzzy_finder_mappings = {
            ["<C-J>"] = "move_cursor_down",
            ["<C-K>"] = "move_cursor_up",
          },
        },
        event_handlers = {
          {
            event = "neo_tree_buffer_enter",
            handler = function()
              vim.opt_local.signcolumn = "auto"
              vim.opt_local.foldcolumn = "0"
            end,
          },
        },
      }
    end,
  },
  {
    "epwalsh/obsidian.nvim",
    branch = "main",
    ft = "markdown",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
    opts = {
      workspaces = {
        {
          name = config.get().vault.name,
          path = paths.vault_root,
        },
      },
      notes_subdir = "in",
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
