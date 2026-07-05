local config = require("upsc_notes.config")
local cfg = config.setup()

vim.g.mapleader = cfg.leader
vim.g.maplocalleader = cfg.localleader

if vim.fn.has(cfg.min_nvim) ~= 1 then
  error(
    ("This config requires Neovim %s. Run /home/bhickta/.local/bin/nvim or restart your shell so ~/.local/bin comes before /usr/bin."):format(
      cfg.min_nvim_label
    )
  )
end

require("upsc_notes.options").setup()
require("upsc_notes.lazy").setup()
require("upsc_notes.keymaps").setup()
require("upsc_notes.autocmds").setup()
require("upsc_notes.commands").setup()
