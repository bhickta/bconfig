local M = {}

local popup_win
local popup_buf
local queue_token = 0
local request_token = 0
local cache = {}
local cache_order = {}
local max_cache_entries = 256

local function config()
  return require("upsc_notes.config").get().translation
end

local function is_visual_mode(mode)
  return mode == "v" or mode == "V" or mode == "\22"
end

function M.is_note_buffer(buf)
  return require("upsc_notes.buffer").is_readable_markdown(buf)
end

local function normalized_positions(start_row, start_col, end_row, end_col)
  if start_row > end_row or (start_row == end_row and start_col > end_col) then
    return end_row, end_col, start_row, start_col
  end
  return start_row, start_col, end_row, end_col
end

local function inclusive_character_end(line, byte_column)
  if line == "" or byte_column > #line then
    return #line
  end
  local character_index = vim.str_utfindex(line, math.max(0, byte_column - 1))
  return vim.str_byteindex(line, character_index + 1)
end

function M.selection_text(lines, start_row, start_col, end_row, end_col, mode)
  start_row, start_col, end_row, end_col = normalized_positions(start_row, start_col, end_row, end_col)
  local selected = vim.list_slice(lines, start_row, end_row)
  if #selected == 0 then
    return ""
  end

  if mode == "V" then
    return table.concat(selected, "\n")
  end

  if mode == "\22" then
    for index, line in ipairs(selected) do
      selected[index] = line:sub(start_col, inclusive_character_end(line, end_col))
    end
    return table.concat(selected, "\n")
  end

  if #selected == 1 then
    selected[1] = selected[1]:sub(start_col, inclusive_character_end(selected[1], end_col))
  else
    selected[1] = selected[1]:sub(start_col)
    selected[#selected] = selected[#selected]:sub(1, inclusive_character_end(selected[#selected], end_col))
  end
  return table.concat(selected, "\n")
end

function M.last_selection()
  local first = vim.fn.getpos("'<")
  local last = vim.fn.getpos("'>")
  if first[2] == 0 or last[2] == 0 then
    return ""
  end
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  return vim.trim(M.selection_text(lines, first[2], first[3], last[2], last[3], vim.fn.visualmode()))
end

function M.current_selection()
  local mode = vim.fn.mode()
  if not is_visual_mode(mode) then
    return ""
  end

  local anchor = vim.fn.getpos("v")
  local cursor = vim.api.nvim_win_get_cursor(0)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  return vim.trim(M.selection_text(lines, anchor[2], anchor[3], cursor[1], cursor[2] + 1, mode))
end

function M.parse_google_response(body)
  local ok, data = pcall(vim.json.decode, body)
  if not ok or type(data) ~= "table" or type(data.sentences) ~= "table" then
    return nil
  end

  local parts = {}
  for _, sentence in ipairs(data.sentences) do
    if type(sentence) == "table" and type(sentence.trans) == "string" and sentence.trans ~= "" then
      table.insert(parts, vim.trim(sentence.trans))
    end
  end
  if #parts == 0 then
    return nil
  end

  return {
    text = table.concat(parts, " "):gsub("\n ", "\n"),
    source_lang = data.src,
  }
end

function M.curl_args()
  local cfg = config()
  return {
    cfg.executable,
    "--silent",
    "--show-error",
    "--fail",
    "--request",
    "POST",
    "--data",
    "client=gtx",
    "--data",
    "dj=1",
    "--data",
    "dt=t",
    "--data",
    "sl=" .. cfg.source_lang,
    "--data",
    "tl=" .. cfg.target_lang,
    "--data-urlencode",
    "q@-",
    "https://translate.googleapis.com/translate_a/single",
  }
end

function M.close_popup()
  if popup_win and vim.api.nvim_win_is_valid(popup_win) then
    vim.api.nvim_win_close(popup_win, true)
  end
  popup_win = nil
  popup_buf = nil
end

local function show_popup(text)
  M.close_popup()
  local lines = vim.split(text, "\n", { plain = true })
  local max_width = math.max(1, math.min(72, vim.o.columns - 6))
  local width = 1
  local height = 0
  for _, line in ipairs(lines) do
    local display_width = math.max(1, vim.fn.strdisplaywidth(line))
    width = math.max(width, math.min(display_width, max_width))
    height = height + math.max(1, math.ceil(display_width / max_width))
  end

  popup_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(popup_buf, 0, -1, false, lines)
  vim.bo[popup_buf].bufhidden = "wipe"
  vim.bo[popup_buf].modifiable = false
  popup_win = vim.api.nvim_open_win(popup_buf, false, {
    relative = "cursor",
    row = 1,
    col = 0,
    width = width,
    height = math.min(height, math.max(1, vim.o.lines - 6)),
    style = "minimal",
    border = "rounded",
    focusable = false,
    noautocmd = true,
    zindex = 60,
  })
  vim.wo[popup_win].wrap = true
  vim.wo[popup_win].linebreak = true
  vim.wo[popup_win].winhl = "Normal:NormalFloat,FloatBorder:FloatBorder"
end

local function enabled()
  if vim.g.upsc_selection_translation_enabled == nil then
    vim.g.upsc_selection_translation_enabled = config().enabled
  end
  return vim.g.upsc_selection_translation_enabled == true
end

function M.translate_text(text)
  text = vim.trim(text or "")
  if text == "" then
    return
  end

  local cfg = config()
  local cached = cache[text]
  if cached then
    show_popup(cached)
    return
  end

  if vim.fn.executable(cfg.executable) ~= 1 then
    vim.notify(("Selection translation needs %s on PATH"):format(cfg.executable), vim.log.levels.ERROR)
    return
  end

  request_token = request_token + 1
  local current_request = request_token
  show_popup("अनुवाद…")
  vim.system(M.curl_args(), { text = true, stdin = text }, function(result)
    vim.schedule(function()
      if current_request ~= request_token then
        return
      end
      if result.code ~= 0 then
        M.close_popup()
        vim.notify("Hindi translation failed: " .. vim.trim(result.stderr or "unknown error"), vim.log.levels.ERROR)
        return
      end

      local translated = M.parse_google_response(result.stdout)
      if not translated then
        M.close_popup()
        vim.notify("Hindi translation returned an unexpected response", vim.log.levels.ERROR)
        return
      end
      if translated.source_lang == cfg.target_lang or vim.trim(translated.text) == text then
        M.close_popup()
        return
      end

      if #cache_order >= max_cache_entries then
        cache[table.remove(cache_order, 1)] = nil
      end
      cache[text] = translated.text
      table.insert(cache_order, text)
      show_popup(translated.text)
    end)
  end)
end

function M.translate_selection(opts)
  local text = M.current_selection()
  if text == "" and opts then
    text = M.last_selection()
  end
  M.translate_text(text)
end

function M.queue_selection()
  queue_token = queue_token + 1
  local current_queue = queue_token
  if not enabled() or not M.is_note_buffer() or not is_visual_mode(vim.fn.mode()) then
    request_token = request_token + 1
    M.close_popup()
    return
  end

  vim.defer_fn(function()
    if current_queue == queue_token and is_visual_mode(vim.fn.mode()) then
      M.translate_selection()
    end
  end, config().delay_ms)
end

function M.toggle()
  vim.g.upsc_selection_translation_enabled = not enabled()
  if not vim.g.upsc_selection_translation_enabled then
    queue_token = queue_token + 1
    request_token = request_token + 1
    M.close_popup()
  end
  vim.notify("Visual Hindi translation " .. (vim.g.upsc_selection_translation_enabled and "enabled" or "disabled"))
end

function M.setup(group)
  vim.api.nvim_create_autocmd({ "CursorMoved", "ModeChanged" }, {
    group = group,
    desc = "Translate paused Visual selections to Hindi",
    callback = M.queue_selection,
  })
end

return M
