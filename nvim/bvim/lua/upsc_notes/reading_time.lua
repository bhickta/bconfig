local M = {}

M.modes = { "slow", "medium", "fast", "xfast" }

local word_count_cache = {}

local function config()
  return require("upsc_notes.config").get().reading
end

local function valid_mode(mode)
  return vim.tbl_contains(M.modes, mode)
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
    error(("Unknown reading speed %q (use slow, medium, fast, or xfast)"):format(mode))
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
  buf = buf == 0 and vim.api.nvim_get_current_buf() or buf
  local changedtick = vim.api.nvim_buf_get_changedtick(buf)
  local cached = word_count_cache[buf]
  if cached and cached.changedtick == changedtick then
    return cached.words
  end

  local count = 0
  for _, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    for _ in line:gmatch("%S+") do
      count = count + 1
    end
  end
  word_count_cache[buf] = { changedtick = changedtick, words = count }
  return count
end

function M.estimate(buf, now)
  local mode = M.get_mode()
  local words = M.word_count(buf)
  local minutes = words == 0 and 0 or math.ceil(words / config().speeds[mode])
  local completed_at = os.date("%I:%M %p", (now or os.time()) + minutes * 60):gsub("^0", "")

  return {
    mode = mode,
    words = words,
    minutes = minutes,
    completed_at = completed_at,
  }
end

function M.status(buf)
  local estimate = M.estimate(buf)
  return (" %s %d min / by %s "):format(estimate.mode:upper(), estimate.minutes, estimate.completed_at)
end

return M
