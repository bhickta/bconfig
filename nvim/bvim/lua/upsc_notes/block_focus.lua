local M = {}

local namespace = vim.api.nvim_create_namespace("UpscBlockFocus")
local enabled_buffers = {}

local function indentation(line)
  if line:match("^%s*$") then
    return nil
  end
  return #(line:match("^%s*") or "")
end

function M.block_range(lines, cursor_line)
  if #lines == 0 then
    return 1, 1
  end

  cursor_line = math.max(1, math.min(cursor_line, #lines))
  local base_indent = indentation(lines[cursor_line])
  if not base_indent then
    return cursor_line, cursor_line
  end

  local block_start = cursor_line
  local parent_indent = base_indent
  for line_number = cursor_line - 1, 1, -1 do
    local line_indent = indentation(lines[line_number])
    if line_indent and line_indent < parent_indent then
      block_start = line_number
      parent_indent = line_indent
      if parent_indent == 0 then
        break
      end
    end
  end

  local block_end = block_start
  for line_number = block_start + 1, #lines do
    local line_indent = indentation(lines[line_number])
    if line_indent and line_indent <= parent_indent then
      break
    end
    block_end = line_number
  end

  return block_start, block_end
end

function M.is_enabled(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  return enabled_buffers[buf] == true
end

function M.refresh(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if not enabled_buffers[buf] or not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  vim.api.nvim_buf_clear_namespace(buf, namespace, 0, -1)
  if vim.bo[buf].filetype ~= "markdown" then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  local block_start, block_end = M.block_range(lines, cursor_line)

  local function highlight(first_line, last_line, group, priority)
    if first_line > last_line then
      return
    end
    vim.api.nvim_buf_set_extmark(buf, namespace, first_line - 1, 0, {
      end_row = last_line,
      end_col = 0,
      hl_group = group,
      hl_eol = true,
      priority = priority,
    })
  end

  highlight(1, block_start - 1, "UpscBlockFocusDim", 200)
  highlight(block_start, block_end, "UpscBlockFocus", 100)
  highlight(block_end + 1, #lines, "UpscBlockFocusDim", 200)
end

function M.enable(opts)
  local buf = vim.api.nvim_get_current_buf()
  if vim.bo[buf].filetype ~= "markdown" then
    vim.notify("Block focus is available in Markdown notes", vim.log.levels.WARN)
    return
  end

  enabled_buffers[buf] = true
  M.refresh(buf)
  if not (opts and opts.notify == false) then
    vim.notify("Block focus enabled")
  end
end

function M.disable(opts)
  local buf = vim.api.nvim_get_current_buf()
  enabled_buffers[buf] = nil
  vim.api.nvim_buf_clear_namespace(buf, namespace, 0, -1)
  if not (opts and opts.notify == false) then
    vim.notify("Block focus disabled")
  end
end

function M.toggle()
  if M.is_enabled(vim.api.nvim_get_current_buf()) then
    M.disable()
  else
    M.enable()
  end
end

function M.forget(buf)
  enabled_buffers[buf] = nil
end

return M
