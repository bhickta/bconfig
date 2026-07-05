local config = require("upsc_notes.config")

return {
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
}
