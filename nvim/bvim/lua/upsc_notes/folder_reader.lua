local M = {}

local fs = require("upsc_notes.fs")
local namespace = vim.api.nvim_create_namespace("UpscFolderReader")

local function relative_path(root, path)
  local prefix = root .. "/"
  return path:sub(1, #prefix) == prefix and path:sub(#prefix + 1) or vim.fs.basename(path)
end

local function directory_parts(path)
  local parts = vim.split(path, "/", { plain = true, trimempty = true })
  table.remove(parts)
  return parts
end

function M.markdown_files(root)
  return fs.collect_files(root, {
    recursive = true,
    skipped_directories = fs.metadata_directories,
    include = function(_, name)
      return name:lower():match("%.md$") ~= nil
    end,
  })
end

local function file_lines(path)
  local buf = vim.fn.bufnr(path)
  if buf ~= -1 and vim.api.nvim_buf_is_loaded(buf) then
    return vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  end

  local ok, lines = pcall(vim.fn.readfile, path)
  return ok and lines or nil
end

local function count_words(lines)
  local reading_time = require("upsc_notes.reading_time")
  local words = 0
  for _, line in ipairs(lines) do
    words = words + reading_time.line_word_count(line)
  end
  return words
end

local function fence_marker(line)
  return line:match("^%s*(```+)") or line:match("^%s*(~~~+)")
end

function M.nest_headings(lines, levels)
  levels = levels or 2
  local nested = {}
  local fence_character
  local fence_length

  for _, line in ipairs(lines) do
    local marker = fence_marker(line)
    if marker then
      local character = marker:sub(1, 1)
      if not fence_character then
        fence_character = character
        fence_length = #marker
      elseif character == fence_character and #marker >= fence_length then
        fence_character = nil
        fence_length = nil
      end
      table.insert(nested, line)
    elseif not fence_character then
      local indent, hashes, title = line:match("^(%s*)(#+)(%s+.*)$")
      if hashes and #hashes <= 6 then
        line = indent .. string.rep("#", math.min(6, #hashes + levels)) .. title
      end
      table.insert(nested, line)
    else
      table.insert(nested, line)
    end
  end

  return nested
end

function M.compose(root)
  root = vim.fs.normalize(vim.fn.fnamemodify(vim.fn.expand(root), ":p")):gsub("/$", "")
  local files = M.markdown_files(root)
  local documents = {}
  local total_words = 0

  for _, path in ipairs(files) do
    local lines = file_lines(path)
    if lines then
      local words = count_words(lines)
      total_words = total_words + words
      table.insert(documents, {
        path = path,
        relative_path = relative_path(root, path),
        name = vim.fs.basename(path),
        directories = directory_parts(relative_path(root, path)),
        lines = lines,
        words = words,
      })
    end
  end

  local reading_time = require("upsc_notes.reading_time")
  local mode = reading_time.get_mode()
  local speed = require("upsc_notes.config").get().reading.speeds[mode]
  local minutes = total_words == 0 and 0 or math.ceil(total_words / speed)
  local lines = {
    "# " .. vim.fs.basename(root),
    "",
    ("> Combined folder view · %d notes · %d words · about %d min at %s speed"):format(
      #documents,
      total_words,
      minutes,
      mode
    ),
  }
  local sections = {}
  local previous_directories = {}

  for _, document in ipairs(documents) do
    local common_depth = 0
    while
      common_depth < #previous_directories
      and common_depth < #document.directories
      and previous_directories[common_depth + 1] == document.directories[common_depth + 1]
    do
      common_depth = common_depth + 1
    end

    vim.list_extend(lines, { "", "---", "" })
    for depth = common_depth + 1, #document.directories do
      table.insert(lines, string.rep("#", math.min(6, depth + 1)) .. " " .. document.directories[depth])
      table.insert(lines, "")
    end

    local file_heading_level = math.min(6, #document.directories + 2)
    table.insert(lines, string.rep("#", file_heading_level) .. " " .. document.name)
    table.insert(lines, "")
    local content_start = #lines + 1
    vim.list_extend(lines, M.nest_headings(document.lines, file_heading_level))
    table.insert(sections, {
      path = document.path,
      relative_path = document.relative_path,
      heading_line = content_start - 2,
      content_start = content_start,
      content_end = math.max(content_start, #lines),
      source_line_count = #document.lines,
      words = document.words,
    })
    previous_directories = document.directories
  end

  return {
    root = root,
    lines = lines,
    sections = sections,
    file_count = #documents,
    words = total_words,
    minutes = minutes,
    mode = mode,
  }
end

function M.section_at(sections, line)
  local current
  for _, section in ipairs(sections or {}) do
    if line < section.heading_line then
      break
    end
    current = section
  end
  return current
end

local function window_for_buffer(buf)
  local current_win = vim.api.nvim_get_current_win()
  if vim.api.nvim_win_get_buf(current_win) == buf then
    return current_win
  end

  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
      return win
    end
  end
end

local function capture_position(buf, win)
  if not vim.api.nvim_buf_is_valid(buf) then
    return nil
  end

  win = win or window_for_buffer(buf)
  if not win or not vim.api.nvim_win_is_valid(win) or vim.api.nvim_win_get_buf(win) ~= buf then
    return nil
  end

  local cursor = vim.api.nvim_win_get_cursor(win)
  local section = M.section_at(vim.b[buf].upsc_folder_reader_sections, cursor[1])
  local position = {
    line = cursor[1],
    column = cursor[2],
  }
  if section and cursor[1] <= section.content_end then
    position.relative_path = section.relative_path
    position.section_offset = cursor[1] - section.heading_line
  end
  return position
end

function M.remember_position(buf, win)
  buf = buf or vim.api.nvim_get_current_buf()
  local root = vim.api.nvim_buf_is_valid(buf) and vim.b[buf].upsc_folder_reader_root or nil
  local position = type(root) == "string" and capture_position(buf, win) or nil
  if not position then
    return false
  end

  return require("upsc_notes.folder_history").save(root, position)
end

local function saved_position(root)
  return require("upsc_notes.folder_history").get(root)
end

function M.recent(limit)
  return require("upsc_notes.folder_history").recent(limit)
end

local function restore_position(win, document, position)
  local line = position and tonumber(position.line) or document.sections[1].heading_line
  local column = position and tonumber(position.column) or 0

  if position and type(position.relative_path) == "string" then
    for _, section in ipairs(document.sections) do
      if section.relative_path == position.relative_path then
        local offset = tonumber(position.section_offset) or 0
        line = math.max(section.heading_line, math.min(section.content_end, section.heading_line + offset))
        break
      end
    end
  end

  line = math.max(1, math.min(#document.lines, math.floor(line or 1)))
  local text = document.lines[line] or ""
  column = math.max(0, math.min(#text, math.floor(column or 0)))
  vim.api.nvim_win_set_cursor(win, { line, column })
end

local function buffer_for_root(root)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.b[buf].upsc_folder_reader_root == root then
      return buf
    end
  end
end

local function editor_window()
  if vim.bo.filetype ~= "neo-tree" then
    return vim.api.nvim_get_current_win()
  end

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype ~= "neo-tree" then
      return win
    end
  end

  vim.cmd.vsplit()
  return vim.api.nvim_get_current_win()
end

local function decorate(buf, sections)
  vim.api.nvim_buf_clear_namespace(buf, namespace, 0, -1)
  for index, section in ipairs(sections) do
    vim.api.nvim_buf_set_extmark(buf, namespace, section.heading_line - 1, 0, {
      virt_text = { { (" %d/%d · gf open source "):format(index, #sections), "Comment" } },
      virt_text_pos = "right_align",
    })
  end
end

local function current_section(buf)
  return M.section_at(vim.b[buf].upsc_folder_reader_sections, vim.api.nvim_win_get_cursor(0)[1])
end

local function move_section(direction)
  local buf = vim.api.nvim_get_current_buf()
  local sections = vim.b[buf].upsc_folder_reader_sections or {}
  if #sections == 0 then
    return
  end

  local line = vim.api.nvim_win_get_cursor(0)[1]
  local target
  if direction > 0 then
    for _, section in ipairs(sections) do
      if section.heading_line > line then
        target = section
        break
      end
    end
    target = target or sections[1]
  else
    for index = #sections, 1, -1 do
      if sections[index].heading_line < line then
        target = sections[index]
        break
      end
    end
    target = target or sections[#sections]
  end

  vim.api.nvim_win_set_cursor(0, { target.heading_line, 0 })
  require("upsc_notes.viewport_focus").place(vim.api.nvim_get_current_win())
end

function M.open_source()
  local buf = vim.api.nvim_get_current_buf()
  local section = current_section(buf)
  if not section then
    vim.notify("Move into a note section first", vim.log.levels.INFO)
    return
  end

  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  local source_line = math.max(1, math.min(section.source_line_count, cursor_line - section.content_start + 1))
  vim.cmd("edit " .. vim.fn.fnameescape(section.path))
  vim.api.nvim_win_set_cursor(0, { source_line, 0 })
  require("upsc_notes.viewport_focus").place(vim.api.nvim_get_current_win())
end

local function configure_buffer(buf)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].swapfile = false
  vim.bo[buf].buflisted = false
  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].modifiable = false
  vim.bo[buf].readonly = true

  local function map(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, { buffer = buf, silent = true, nowait = true, desc = desc })
  end

  map("]f", function() move_section(1) end, "Next folder note")
  map("[f", function() move_section(-1) end, "Previous folder note")
  map("gf", M.open_source, "Open source note")
  map("R", function() M.refresh(buf) end, "Refresh folder view")
  map("q", "<cmd>bdelete<cr>", "Close folder view")
end

local function render(buf, document)
  vim.bo[buf].modifiable = true
  vim.bo[buf].readonly = false
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, document.lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].readonly = true
  vim.b[buf].upsc_folder_reader_root = document.root
  vim.b[buf].upsc_folder_reader_sections = document.sections
  decorate(buf, document.sections)
end

function M.refresh(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  local root = vim.b[buf].upsc_folder_reader_root
  if not root then
    return
  end

  local previous_position = capture_position(buf)
  local document = M.compose(root)
  render(buf, document)

  if vim.api.nvim_get_current_buf() == buf then
    restore_position(vim.api.nvim_get_current_win(), document, previous_position)
  end
  vim.notify(("Folder view refreshed: %d notes"):format(document.file_count), vim.log.levels.INFO)
end

function M.open(root)
  root = vim.fs.normalize(vim.fn.fnamemodify(vim.fn.expand(root), ":p")):gsub("/$", "")
  if not fs.is_directory(root) then
    vim.notify("Folder does not exist: " .. root, vim.log.levels.WARN)
    return
  end

  local document = M.compose(root)
  if document.file_count == 0 then
    vim.notify("No Markdown files found in folder: " .. root, vim.log.levels.WARN)
    return
  end

  local buf = buffer_for_root(root) or vim.api.nvim_create_buf(false, true)
  local previous_position = capture_position(buf) or saved_position(root)
  local is_new = vim.api.nvim_buf_get_name(buf) == ""
  if is_new then
    vim.api.nvim_buf_set_name(buf, "folder://" .. root)
  end
  render(buf, document)

  local win = editor_window()
  vim.api.nvim_win_set_buf(win, buf)
  vim.api.nvim_set_current_win(win)
  if is_new then
    configure_buffer(buf)
  end
  restore_position(win, document, previous_position)
  M.remember_position(buf, win)
end

function M.setup()
  local group = vim.api.nvim_create_augroup("UpscFolderReaderPosition", { clear = true })
  vim.api.nvim_create_autocmd("BufLeave", {
    group = group,
    desc = "Remember the cursor position in combined folder views",
    callback = function(event)
      if require("upsc_notes.buffer").is_folder_reader(event.buf) then
        M.remember_position(event.buf, vim.api.nvim_get_current_win())
      end
    end,
  })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    desc = "Persist active combined folder view positions",
    callback = function()
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        if require("upsc_notes.buffer").is_folder_reader(buf) then
          M.remember_position(buf, win)
        end
      end
    end,
  })
end

return M
