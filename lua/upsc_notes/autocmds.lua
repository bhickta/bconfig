local actions = require("upsc_notes.actions")

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.breakindent = true
    vim.opt_local.conceallevel = 1
    vim.opt_local.textwidth = 0
    vim.opt_local.spell = false

    vim.keymap.set("n", "<cr>", "<cmd>ObsidianFollowLink<cr>", {
      buffer = true,
      silent = true,
      desc = "Follow Obsidian link",
    })

    vim.keymap.set("n", "<bs>", "<c-o>", {
      buffer = true,
      silent = true,
      desc = "Jump back",
    })
  end,
})

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    if vim.fn.argc() == 0 and #vim.api.nvim_list_uis() > 0 then
      actions.open_dashboard()
    end
  end,
})
