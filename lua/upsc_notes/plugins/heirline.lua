return {
  {
    "rebelot/heirline.nvim",
    event = "BufEnter",
    config = function()
      require("upsc_notes.astroui.status").setup()
    end,
  },
}
