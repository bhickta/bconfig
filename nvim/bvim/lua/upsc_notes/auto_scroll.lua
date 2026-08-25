local M = {}

local session
local generation = 0

local function reading_time()
  return require("upsc_notes.reading_time")
end

local function emit_change()
  vim.api.nvim_exec_autocmds("User", { pattern = "UpscAutoScrollChanged" })
  vim.cmd.redrawstatus()
end

function M.is_active(buf)
  if buf == 0 then
    buf = vim.api.nvim_get_current_buf()
  end
  return session ~= nil and (buf == nil or session.buf == buf)
end

function M.delay_for_line(line)
  local cfg = require("upsc_notes.config").get().reading
  local words_per_minute = cfg.speeds[reading_time().get_mode()]
  local words = reading_time().line_word_count(line)
  if words == 0 then
    return 50
  end
  return math.max(50, math.floor((words * 60000 / words_per_minute) + 0.5))
end

function M.stop(opts)
  local was_active = session ~= nil
  generation = generation + 1
  session = nil
  if was_active then
    emit_change()
    if not (opts and opts.notify == false) then
      vim.notify("Auto-scroll stopped")
    end
  end
end

local function schedule_current_line()
  if not session then
    return
  end

  generation = generation + 1
  local current_generation = generation
  local current_session = session
  local cursor_line = vim.api.nvim_win_get_cursor(current_session.win)[1]
  local line = vim.api.nvim_buf_get_lines(current_session.buf, cursor_line - 1, cursor_line, false)[1] or ""
  current_session.scheduled_line = cursor_line

  local function advance()
    if current_generation ~= generation or session ~= current_session then
      return
    end
    if not vim.api.nvim_win_is_valid(current_session.win)
      or not vim.api.nvim_buf_is_valid(current_session.buf)
      or vim.api.nvim_win_get_buf(current_session.win) ~= current_session.buf
      or vim.api.nvim_get_current_win() ~= current_session.win
    then
      M.stop({ notify = false })
      return
    end
    if vim.api.nvim_get_mode().mode ~= "n" then
      vim.defer_fn(advance, 200)
      return
    end

    local line_number = vim.api.nvim_win_get_cursor(current_session.win)[1]
    if line_number ~= current_session.scheduled_line then
      schedule_current_line()
      return
    end
    if line_number >= vim.api.nvim_buf_line_count(current_session.buf) then
      M.stop({ notify = false })
      vim.notify("Auto-scroll complete")
      return
    end

    vim.api.nvim_win_set_cursor(current_session.win, { line_number + 1, 0 })
    vim.api.nvim_win_call(current_session.win, function()
      vim.cmd("normal! zz")
    end)
    vim.cmd.redrawstatus()
    schedule_current_line()
  end

  vim.defer_fn(advance, M.delay_for_line(line))
end

function M.start(opts)
  local buf = vim.api.nvim_get_current_buf()
  if vim.bo[buf].filetype ~= "markdown" or vim.bo[buf].buftype ~= "" then
    vim.notify("Auto-scroll is available in Markdown notes", vim.log.levels.WARN)
    return
  end

  if session then
    M.stop({ notify = false })
  end
  session = { buf = buf, win = vim.api.nvim_get_current_win() }
  emit_change()
  schedule_current_line()
  if not (opts and opts.notify == false) then
    local mode = reading_time().get_mode()
    vim.notify(("Auto-scroll started at %s speed"):format(mode))
  end
end

function M.toggle()
  if M.is_active(vim.api.nvim_get_current_buf()) then
    M.stop()
  else
    M.start()
  end
end

function M.reschedule()
  if session then
    schedule_current_line()
    emit_change()
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup("UpscAutoScroll", { clear = true })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "UpscReadingSpeedChanged",
    callback = M.reschedule,
  })
  vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
    group = group,
    callback = function(event)
      if M.is_active(event.buf) then
        M.stop({ notify = false })
      end
    end,
  })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      M.stop({ notify = false })
    end,
  })
end

return M
