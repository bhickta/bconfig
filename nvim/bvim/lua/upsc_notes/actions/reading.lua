local config = require("upsc_notes.config")
local paths = require("upsc_notes.paths")

local M = {}

local function apply_reading_mode(enabled)
  config.apply_markdown_reading_options(enabled)
  vim.wo.number = false
  vim.wo.relativenumber = true
  vim.wo.signcolumn = enabled and "no" or "yes"
  vim.wo.foldcolumn = "0"
  vim.wo.cursorline = not enabled
  vim.wo.list = false
end

function M.jump_to_next_wikilink()
  vim.fn.search("\\[\\[[^]]\\+\\]\\]", "W")
end

function M.jump_to_prev_wikilink()
  vim.fn.search("\\[\\[[^]]\\+\\]\\]", "bW")
end

function M.apply_current_window_mode()
  if vim.bo.filetype == "markdown" then
    apply_reading_mode(not vim.bo.modifiable or vim.b.upsc_study_mode == true)
  end
end

function M.set_read_mode(opts)
  opts = opts or {}
  vim.opt_local.readonly = false
  vim.opt_local.modifiable = false
  apply_reading_mode(true)
  if opts.notify ~= false then
    vim.notify("Read mode: buffer locked", vim.log.levels.INFO)
  end
end

function M.set_edit_mode(opts)
  opts = opts or {}
  if require("upsc_notes.buffer").is_folder_reader() then
    if opts.notify ~= false then
      vim.notify("The combined folder view is read-only; use gf to edit its source note", vim.log.levels.INFO)
    end
    return
  end
  vim.opt_local.modifiable = true
  vim.opt_local.readonly = false
  apply_reading_mode(false)
  if opts.notify ~= false then
    vim.notify("Edit mode: buffer unlocked", vim.log.levels.INFO)
  end
end

function M.toggle_read_edit_mode()
  if vim.bo.modifiable then
    M.set_read_mode()
  else
    M.set_edit_mode()
  end
end

function M.enable_study_mode()
  vim.b.upsc_study_mode = true
  apply_reading_mode(true)
  vim.notify("Study mode: clean reading area", vim.log.levels.INFO)
end

function M.disable_study_mode()
  vim.b.upsc_study_mode = false
  apply_reading_mode(false)
  vim.notify("Study mode off", vim.log.levels.INFO)
end

function M.toggle_study_mode()
  if vim.b.upsc_study_mode then
    M.disable_study_mode()
  else
    M.enable_study_mode()
  end
end

function M.toggle_markdown_render()
  local ok, render = pcall(require, "render-markdown")
  if ok then
    render.toggle()
  else
    vim.notify("render-markdown.nvim is not available", vim.log.levels.WARN)
  end
end

function M.toggle_zen()
  local ok, snacks = pcall(require, "snacks")
  if ok and snacks.zen then
    snacks.zen()
  else
    vim.notify("Snacks zen is not available", vim.log.levels.WARN)
  end
end

function M.dismiss_notifications()
  local ok, notifier = pcall(require, "snacks.notifier")
  if ok then
    notifier.hide()
  end
end

function M.open_dashboard()
  vim.cmd("cd " .. vim.fn.fnameescape(paths.vault_root))
  vim.cmd("Alpha")
end

return M
