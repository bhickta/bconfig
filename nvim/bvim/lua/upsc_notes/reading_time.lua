local M = {}

M.modes = { "xxslow", "xslow", "slow", "medium", "fast", "xfast" }

local word_count_cache = {}

local function config()
  return require("upsc_notes.config").get().reading
end

local function valid_mode(mode)
  return vim.tbl_contains(M.modes, mode)
end

function M.line_word_count(line)
  local count = 0
  for _ in line:gmatch("%S+") do
    count = count + 1
  end
  return count
end

local function cached_counts(buf)
  buf = buf == 0 and vim.api.nvim_get_current_buf() or buf
  local changedtick = vim.api.nvim_buf_get_changedtick(buf)
  local cached = word_count_cache[buf]
  if cached and cached.changedtick == changedtick then
    return cached
  end

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local suffix = { [#lines + 1] = 0 }
  for line_number = #lines, 1, -1 do
    suffix[line_number] = suffix[line_number + 1] + M.line_word_count(lines[line_number])
  end
  cached = { changedtick = changedtick, words = suffix[1] or 0, suffix = suffix, line_count = #lines }
  word_count_cache[buf] = cached
  return cached
end

function M.get_mode()
  local mode = vim.g.upsc_reading_speed_mode
  if not valid_mode(mode) then
    mode = config().default_speed
    vim.g.upsc_reading_speed_mode = mode
  end
  return mode
end

function M.set_mode(mode, opts)
  mode = mode:lower()
  if not valid_mode(mode) then
    error(("Unknown reading speed %q (use %s)"):format(mode, table.concat(M.modes, ", ")))
  end

  vim.g.upsc_reading_speed_mode = mode
  vim.api.nvim_exec_autocmds("User", { pattern = "UpscReadingSpeedChanged" })
  vim.cmd.redrawstatus()

  if not (opts and opts.notify == false) then
    vim.notify(("Reading speed: %s (%d words/min)"):format(mode, config().speeds[mode]))
  end
end

function M.cycle_mode(opts)
  local current = M.get_mode()
  local index = vim.fn.index(M.modes, current) + 1
  M.set_mode(M.modes[(index % #M.modes) + 1], opts)
end

function M.word_count(buf)
  return cached_counts(buf).words
end

function M.word_count_from(buf, start_line)
  local cached = cached_counts(buf)
  start_line = math.max(1, math.min(start_line or 1, cached.line_count + 1))
  return cached.suffix[start_line] or 0
end

function M.estimate(buf, now, start_line)
  local mode = M.get_mode()
  local words = M.word_count_from(buf, start_line)
  local minutes = words == 0 and 0 or math.ceil(words / config().speeds[mode])
  local completed_at = os.date("%I:%M %p", (now or os.time()) + minutes * 60):gsub("^0", "")

  return {
    mode = mode,
    words = words,
    minutes = minutes,
    completed_at = completed_at,
  }
end

function M.status(buf, opts)
  opts = opts or {}
  local estimate = M.estimate(buf, nil, opts.start_line)
  local marker = opts.active and "▶ " or ""
  return (" %s%s %d min / by %s "):format(marker, estimate.mode:upper(), estimate.minutes, estimate.completed_at)
end

return M
