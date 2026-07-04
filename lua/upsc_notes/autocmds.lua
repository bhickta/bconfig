local actions = require("upsc_notes.actions")

local function is_real_file(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  return name ~= "" and vim.bo[buf].buftype == ""
end

vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight yanked text",
  callback = function()
    vim.hl.on_yank()
  end,
})

vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  desc = "Check whether open files changed outside Neovim",
  callback = function()
    if vim.bo.buftype ~= "nofile" then
      vim.cmd("checktime")
    end
  end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
  desc = "Create parent directories before saving",
  callback = function(event)
    if not is_real_file(event.buf) or event.match:match("^%w+:[\\/][\\/]") then
      return
    end

    local dir = vim.fs.dirname(vim.uv.fs_realpath(event.match) or event.match)
    if dir then
      vim.fn.mkdir(vim.fs.abspath(dir), "p")
    end
  end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  desc = "Restore last cursor position",
  callback = function(event)
    if vim.b[event.buf].upsc_last_loc_restored then
      return
    end

    vim.b[event.buf].upsc_last_loc_restored = true
    local mark = vim.api.nvim_buf_get_mark(event.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(event.buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

vim.api.nvim_create_autocmd("BufWinEnter", {
  desc = "Let q close utility windows",
  callback = function(event)
    if vim.g.upsc_q_close_windows and vim.g.upsc_q_close_windows[event.buf] then
      return
    end

    vim.g.upsc_q_close_windows = vim.g.upsc_q_close_windows or {}
    vim.g.upsc_q_close_windows[event.buf] = true

    for _, map in ipairs(vim.api.nvim_buf_get_keymap(event.buf, "n")) do
      if map.lhs == "q" then
        return
      end
    end

    if vim.tbl_contains({ "help", "nofile", "quickfix" }, vim.bo[event.buf].buftype) then
      vim.keymap.set("n", "q", "<cmd>close<cr>", {
        buffer = event.buf,
        silent = true,
        nowait = true,
        desc = "Close window",
      })
    end
  end,
})

vim.api.nvim_create_autocmd("BufDelete", {
  desc = "Clean q-close cache",
  callback = function(event)
    if vim.g.upsc_q_close_windows then
      vim.g.upsc_q_close_windows[event.buf] = nil
    end
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  desc = "Unlist quickfix buffers",
  pattern = "qf",
  callback = function()
    vim.opt_local.buflisted = false
  end,
})

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
