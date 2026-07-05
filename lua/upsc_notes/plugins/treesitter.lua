return {
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
}
