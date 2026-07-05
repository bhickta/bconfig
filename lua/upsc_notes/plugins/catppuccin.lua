return {
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
      require("upsc_notes.astroui").setup()
    end,
  },
}
