local actions = require("upsc_notes.actions")

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.breakindent = true
    vim.opt_local.breakindentopt = "shift:2,min:40,sbr"
    vim.opt_local.showbreak = "  "
    vim.opt_local.conceallevel = 2
    vim.opt_local.concealcursor = "nc"
    vim.opt_local.textwidth = 0
    vim.opt_local.spell = false
    vim.opt_local.colorcolumn = ""
    vim.opt_local.cursorline = true
    vim.opt_local.foldenable = false
    vim.opt_local.formatoptions:remove({ "t", "c", "r", "o" })

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

    vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", {
      buffer = true,
      expr = true,
      silent = true,
      desc = "Down visual line",
    })

    vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", {
      buffer = true,
      expr = true,
      silent = true,
      desc = "Up visual line",
    })
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "neo-tree",
  callback = function(event)
    local maps = {
      { "<leader>tz", actions.open_zettel_tree, "Zettelkasten tree" },
      { "<leader>ti", actions.open_in_tree, "In tree" },
      { "<leader>tt", actions.toggle_tree, "Toggle tree" },
      { "<leader>te", actions.toggle_tree_focus, "Editor/tree focus" },
      { "<leader>tc", actions.reveal_current_note, "Reveal current note" },
      { "<leader>tf", actions.focus_tree, "Focus tree here" },
      { "<leader>tu", actions.unfocus_tree, "Unfocus tree" },
      { "<leader>e", actions.toggle_tree, "Toggle Explorer" },
      { "<leader>o", actions.focus_tree_panel, "Toggle Explorer Focus" },
    }

    for _, map in ipairs(maps) do
      vim.keymap.set("n", map[1], map[2], {
        buffer = event.buf,
        silent = true,
        noremap = true,
        desc = map[3],
      })
    end
  end,
})

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    if vim.fn.argc() == 0 and #vim.api.nvim_list_uis() > 0 then
      actions.open_dashboard()
    end
  end,
})
