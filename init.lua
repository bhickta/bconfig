vim.g.mapleader = " "
vim.g.maplocalleader = " "

if vim.fn.has("nvim-0.12") ~= 1 then
  error("This config requires Neovim 0.12+. Run /home/bhickta/.local/bin/nvim or restart your shell so ~/.local/bin comes before /usr/bin.")
end

require("upsc_notes.options")
require("upsc_notes.lazy")
require("upsc_notes.keymaps")
require("upsc_notes.autocmds")
require("upsc_notes.commands")
