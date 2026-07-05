local actions = require("upsc_notes.actions")
local config = require("upsc_notes.config")
local shortcuts = require("upsc_notes.shortcuts")

local M = {}

local function is_real_file(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  return name ~= "" and vim.bo[buf].buftype == ""
end

local function alpha_visible()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "alpha" then
      return true
    end
  end
  return false
end

function M.setup()
  local group = vim.api.nvim_create_augroup("UpscNotesAutocmds", { clear = true })

  vim.api.nvim_create_autocmd("TextYankPost", {
    group = group,
    desc = "Highlight yanked text",
    callback = function()
      vim.hl.on_yank()
    end,
  })

  vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
    group = group,
    desc = "Check whether open files changed outside Neovim",
    callback = function()
      if vim.bo.buftype ~= "nofile" then
        vim.cmd("checktime")
      end
    end,
  })

  vim.api.nvim_create_autocmd("BufWritePre", {
    group = group,
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
    group = group,
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
    group = group,
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
    group = group,
    desc = "Clean q-close cache",
    callback = function(event)
      if vim.g.upsc_q_close_windows then
        vim.g.upsc_q_close_windows[event.buf] = nil
      end
    end,
  })

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    desc = "Unlist quickfix buffers",
    pattern = "qf",
    callback = function()
      vim.opt_local.buflisted = false
    end,
  })

  vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter", "WinEnter" }, {
    group = group,
    desc = "Keep dashboard layout stable",
    callback = function()
      if vim.bo.filetype ~= "alpha" then
        return
      end
      vim.wo.wrap = false
      vim.wo.linebreak = false
    end,
  })

  vim.api.nvim_create_autocmd({ "WinResized", "WinNew", "WinClosed" }, {
    group = group,
    desc = "Redraw dashboard after layout changes",
    callback = function()
      if not alpha_visible() then
        return
      end

      vim.schedule(function()
        if alpha_visible() then
          pcall(vim.cmd.AlphaRedraw)
        end
      end)
    end,
  })

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "markdown",
    callback = function()
      config.apply_markdown_buffer_options()
      vim.opt_local.formatoptions:remove({ "t", "c", "r", "o" })
      actions.set_read_mode({ notify = false })

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

  vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
    group = group,
    desc = "Restore markdown read/edit window mode",
    callback = function()
      actions.apply_current_window_mode()
    end,
  })

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "neo-tree",
    callback = function(event)
      vim.wo.wrap = true
      vim.wo.linebreak = true
      vim.wo.sidescrolloff = 0
      vim.wo.statuscolumn = ""

      for _, shortcut in ipairs(shortcuts.tree_buffer(actions)) do
        vim.keymap.set(shortcut.mode, shortcut.lhs, shortcut.rhs, {
          buffer = event.buf,
          silent = true,
          noremap = true,
          desc = shortcut.desc,
        })
      end
    end,
  })

  vim.api.nvim_create_autocmd("VimEnter", {
    group = group,
    callback = function()
      if vim.fn.argc() == 0 and #vim.api.nvim_list_uis() > 0 then
        actions.open_dashboard()
      end
    end,
  })
end

return M
