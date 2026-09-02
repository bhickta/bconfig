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

local function belongs_to_session(buf)
  return session ~= nil and (buf == nil or session.buf == buf)
end

function M.is_active(buf)
  if buf == 0 then
    buf = vim.api.nvim_get_current_buf()
  end
  return belongs_to_session(buf) and not session.paused
end

function M.is_paused(buf)
  if buf == 0 then
    buf = vim.api.nvim_get_current_buf()
  end
  return belongs_to_session(buf) and session.paused
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
  if not session or session.paused then
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
    require("upsc_notes.viewport_focus").place(current_session.win)
    vim.cmd.redrawstatus()
    schedule_current_line()
  end

  vim.defer_fn(advance, M.delay_for_line(line))
end

function M.start(opts)
  local buf = vim.api.nvim_get_current_buf()
  if not require("upsc_notes.buffer").is_readable_markdown(buf) then
    vim.notify("Auto-scroll is available in Markdown notes", vim.log.levels.WARN)
    return
  end

  if session then
    M.stop({ notify = false })
  end
  local win = vim.api.nvim_get_current_win()
  session = { buf = buf, win = win, paused = false }
  emit_change()
  schedule_current_line()
  if not (opts and opts.notify == false) then
    local mode = reading_time().get_mode()
    vim.notify(("Auto-scroll started at %s speed"):format(mode))
  end
end

function M.pause(opts)
  if not session or session.paused then
    return false
  end

  generation = generation + 1
  session.paused = true
  emit_change()
  if not (opts and opts.notify == false) then
    vim.notify("Auto-scroll paused")
  end
  return true
end

function M.resume(opts)
  if not session or not session.paused then
    return false
  end

  if
    not vim.api.nvim_win_is_valid(session.win)
    or not vim.api.nvim_buf_is_valid(session.buf)
    or vim.api.nvim_win_get_buf(session.win) ~= session.buf
    or vim.api.nvim_get_current_win() ~= session.win
  then
    M.stop({ notify = false })
    return false
  end

  session.paused = false
  emit_change()
  schedule_current_line()
  if not (opts and opts.notify == false) then
    local mode = reading_time().get_mode()
    vim.notify(("Auto-scroll resumed at %s speed"):format(mode))
  end
  return true
end

function M.toggle()
  if M.is_active(vim.api.nvim_get_current_buf()) then
    M.pause()
  elseif M.is_paused(vim.api.nvim_get_current_buf()) then
    M.resume()
  else
    M.start()
  end
end

function M.reschedule()
  if session and not session.paused then
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
  vim.api.nvim_create_autocmd("CursorMoved", {
    group = group,
    desc = "Adjust auto-scroll timing after manual movement",
    callback = function(event)
      if
        session
        and not session.paused
        and event.buf == session.buf
        and vim.api.nvim_win_is_valid(session.win)
        and vim.api.nvim_win_get_cursor(session.win)[1] ~= session.scheduled_line
      then
        schedule_current_line()
      end
    end,
  })
  vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
    group = group,
    callback = function(event)
      if belongs_to_session(event.buf) then
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
