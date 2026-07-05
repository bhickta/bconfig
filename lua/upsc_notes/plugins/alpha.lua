return {
  {
    "goolord/alpha-nvim",
    cmd = "Alpha",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("upsc_notes.plugins.configs.alpha").setup()
    end,
  },
}
