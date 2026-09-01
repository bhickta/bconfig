local M = {}

local uv = vim.uv or vim.loop
local namespace = vim.api.nvim_create_namespace("UpscFolderReader")
local skipped_directories = {
  [".git"] = true,
  [".smart-env"] = true,
  [".trash"] = true,
}

local function is_directory(path)
  local stat = uv.fs_stat(path)
  return stat and stat.type == "directory"
end

local function relative_path(root, path)
  local prefix = root .. "/"
  return path:sub(1, #prefix) == prefix and path:sub(#prefix + 1) or vim.fs.basename(path)
end

function M.markdown_files(root)
  root = vim.fs.normalize(vim.fn.fnamemodify(vim.fn.expand(root), ":p")):gsub("/$", "")
  local files = {}

  local function scan(directory)
    local handle = uv.fs_scandir(directory)
    if not handle then
      return
    end

    while true do
      local name, kind = uv.fs_scandir_next(handle)
      if not name then
        break
      end

      local path = vim.fs.joinpath(directory, name)
      if kind == "directory" and not skipped_directories[name] then
        scan(path)
      elseif kind == "file" and name:lower():match("%.md$") then
        table.insert(files, vim.fs.normalize(path))
      end
    end
  end

  scan(root)
  table.sort(files, function(left, right)
    local left_relative = relative_path(root, left)
    local right_relative = relative_path(root, right)
    local left_folded = left_relative:lower()
    local right_folded = right_relative:lower()
    return left_folded == right_folded and left_relative < right_relative or left_folded < right_folded
  end)
  return files
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

  for _, document in ipairs(documents) do
    vim.list_extend(lines, { "", "---", "", "## " .. document.relative_path, "" })
    local content_start = #lines + 1
    vim.list_extend(lines, document.lines)
    table.insert(sections, {
      path = document.path,
      relative_path = document.relative_path,
      heading_line = content_start - 2,
      content_start = content_start,
      content_end = math.max(content_start, #lines),
      source_line_count = #document.lines,
      words = document.words,
    })
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
  vim.cmd("normal! zz")
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
  vim.cmd("normal! zz")
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

  local previous = current_section(buf)
  local previous_path = previous and previous.path
  local document = M.compose(root)
  render(buf, document)

  if vim.api.nvim_get_current_buf() == buf then
    for _, section in ipairs(document.sections) do
      if section.path == previous_path then
        vim.api.nvim_win_set_cursor(0, { section.heading_line, 0 })
        break
      end
    end
  end
  vim.notify(("Folder view refreshed: %d notes"):format(document.file_count), vim.log.levels.INFO)
end

function M.open(root)
  root = vim.fs.normalize(vim.fn.fnamemodify(vim.fn.expand(root), ":p")):gsub("/$", "")
  if not is_directory(root) then
    vim.notify("Folder does not exist: " .. root, vim.log.levels.WARN)
    return
  end

  local document = M.compose(root)
  if document.file_count == 0 then
    vim.notify("No Markdown files found in folder: " .. root, vim.log.levels.WARN)
    return
  end

  local buf = buffer_for_root(root) or vim.api.nvim_create_buf(false, true)
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
  vim.api.nvim_win_set_cursor(win, { document.sections[1].heading_line, 0 })
end

return M
