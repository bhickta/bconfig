local M = {}

local file_cache = {}

local function reading_config()
  return require("upsc_notes.config").get().reading
end

local function markdown_files(dir)
  local files = {}
  local handle = (vim.uv or vim.loop).fs_scandir(dir)
  if not handle then
    return files
  end

  while true do
    local name, kind = (vim.uv or vim.loop).fs_scandir_next(handle)
    if not name then
      break
    end
    if kind == "file" and name:lower():match("%.md$") then
      table.insert(files, vim.fs.joinpath(dir, name))
    end
  end

  table.sort(files, function(left, right)
    local left_name = vim.fs.basename(left):lower()
    local right_name = vim.fs.basename(right):lower()
    return left_name == right_name and left < right or left_name < right_name
  end)
  return files
end

function M.files_below(selected_path)
  selected_path = vim.fs.normalize(selected_path)
  local files = markdown_files(vim.fs.dirname(selected_path))
  local below = {}
  local selected_seen = false
  for _, path in ipairs(files) do
    if selected_seen then
      table.insert(below, path)
    elseif vim.fs.normalize(path) == selected_path then
      selected_seen = true
    end
  end
  return below
end

local function disk_word_count(path)
  local stat = (vim.uv or vim.loop).fs_stat(path)
  if not stat then
    return 0
  end
  local cache_key = table.concat({ stat.size or 0, stat.mtime.sec or 0, stat.mtime.nsec or 0 }, ":")
  local cached = file_cache[path]
  if cached and cached.key == cache_key then
    return cached.words
  end

  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    return 0
  end
  local words = 0
  for _, line in ipairs(lines) do
    words = words + require("upsc_notes.reading_time").line_word_count(line)
  end
  file_cache[path] = { key = cache_key, words = words }
  return words
end

local function file_word_count(path)
  local buf = vim.fn.bufnr(path)
  if buf ~= -1 and vim.api.nvim_buf_is_loaded(buf) then
    return require("upsc_notes.reading_time").word_count(buf)
  end
  return disk_word_count(path)
end

function M.estimate(selected_path, now)
  local files = M.files_below(selected_path)
  local words = 0
  for _, path in ipairs(files) do
    words = words + file_word_count(path)
  end

  local reading_time = require("upsc_notes.reading_time")
  local mode = reading_time.get_mode()
  local minutes = words == 0 and 0 or math.ceil(words / reading_config().speeds[mode])
  local completed_at = os.date("%I:%M %p", (now or os.time()) + minutes * 60):gsub("^0", "")
  return {
    folder = vim.fs.basename(vim.fs.dirname(selected_path)),
    files = files,
    file_count = #files,
    words = words,
    mode = mode,
    minutes = minutes,
    completed_at = completed_at,
  }
end

function M.status(selected_path)
  local estimate = M.estimate(selected_path)
  return (" ↓ %s %d notes %s %d min / by %s "):format(
    estimate.folder,
    estimate.file_count,
    estimate.mode:upper(),
    estimate.minutes,
    estimate.completed_at
  )
end

return M
