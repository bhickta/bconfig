local M = {}

local function resolve(buf)
  if buf == nil or buf == 0 then
    return vim.api.nvim_get_current_buf()
  end
  return buf
end

function M.is_folder_reader(buf)
  buf = resolve(buf)
  return vim.api.nvim_buf_is_valid(buf) and type(vim.b[buf].upsc_folder_reader_root) == "string"
end

function M.is_readable_markdown(buf)
  buf = resolve(buf)
  if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].filetype ~= "markdown" then
    return false
  end
  return vim.bo[buf].buftype == "" or M.is_folder_reader(buf)
end

function M.is_standard_or_folder(buf)
  buf = resolve(buf)
  return vim.api.nvim_buf_is_valid(buf) and (vim.bo[buf].buftype == "" or M.is_folder_reader(buf))
end

return M
