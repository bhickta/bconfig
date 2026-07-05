local config = require("upsc_notes.config")
local paths = require("upsc_notes.paths")

return {
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
