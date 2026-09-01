local M = {}

local function listed_buffers()
  return vim.tbl_filter(function(buf)
    return vim.api.nvim_buf_is_valid(buf.bufnr) and buf.listed == 1
  end, vim.fn.getbufinfo({ buflisted = 1 }))
end

local function fallback_buffer(current)
  for _, buf in ipairs(listed_buffers()) do
    if buf.bufnr ~= current then
      return buf.bufnr
    end
  end
end

function M.next_buffer()
  if #listed_buffers() < 2 then
    vim.notify("No next file buffer", vim.log.levels.INFO)
    return
  end
  vim.cmd.bnext()
end

function M.prev_buffer()
  if #listed_buffers() < 2 then
    vim.notify("No previous file buffer", vim.log.levels.INFO)
    return
  end
  vim.cmd.bprevious()
end

function M.alternate_buffer()
  local alternate = vim.fn.bufnr("#")
  if alternate > 0 and vim.api.nvim_buf_is_valid(alternate) and vim.bo[alternate].buflisted then
    vim.cmd.buffer("#")
  else
    vim.notify("No alternate file buffer", vim.log.levels.INFO)
  end
end

function M.close_buffer()
  local current = vim.api.nvim_get_current_buf()
  if vim.bo[current].modified then
    vim.cmd("confirm bdelete")
    return
  end

  local fallback = fallback_buffer(current)
  if fallback then
    vim.cmd.buffer(fallback)
  else
    vim.cmd.enew()
  end
  if vim.api.nvim_buf_is_valid(current) then
    vim.cmd.bdelete(current)
  end
end

function M.close_other_buffers()
  local current = vim.api.nvim_get_current_buf()
  local closed = 0
  for _, buf in ipairs(listed_buffers()) do
    if buf.bufnr ~= current then
      vim.cmd("confirm bdelete " .. buf.bufnr)
      if not vim.api.nvim_buf_is_valid(buf.bufnr) or not vim.bo[buf.bufnr].buflisted then
        closed = closed + 1
      end
    end
  end

  if closed == 0 then
    vim.notify("No other file buffers to close", vim.log.levels.INFO)
  else
    vim.notify(("Closed %d other file buffer%s"):format(closed, closed == 1 and "" or "s"), vim.log.levels.INFO)
  end
end

return M
