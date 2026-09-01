local M = {}

local focus_ratio = 0.20
local last_views = {}
local repositioning = {}
local scroll_up = vim.api.nvim_replace_termcodes("<C-y>", true, false, true)

local function supported(win)
  if not vim.api.nvim_win_is_valid(win) then
    return false
  end
  return require("upsc_notes.buffer").is_standard_or_folder(vim.api.nvim_win_get_buf(win))
end

local function snapshot(win)
  if not vim.api.nvim_win_is_valid(win) then
    return nil
  end

  return vim.api.nvim_win_call(win, function()
    local view = vim.fn.winsaveview()
    return {
      buf = vim.api.nvim_get_current_buf(),
      cursor_line = vim.api.nvim_win_get_cursor(0)[1],
      height = vim.api.nvim_win_get_height(0),
      topline = view.topline,
      skipcol = view.skipcol,
    }
  end)
end

function M.target_offset(height)
  return math.max(0, math.floor((height - 1) * focus_ratio))
end

function M.place(win)
  win = win or vim.api.nvim_get_current_win()
  if repositioning[win] then
    return false
  end
  if not supported(win) then
    last_views[win] = nil
    return false
  end

  repositioning[win] = true
  local ok = pcall(vim.api.nvim_win_call, win, function()
    vim.cmd("normal! zt")
    local offset = M.target_offset(vim.api.nvim_win_get_height(0))
    if offset > 0 then
      vim.cmd("normal! " .. offset .. scroll_up)
    end
  end)
  repositioning[win] = nil

  if ok then
    last_views[win] = snapshot(win)
  end
  return ok
end

local function place_after_external_scroll(win)
  local current = snapshot(win)
  if current and not vim.deep_equal(current, last_views[win]) then
    M.place(win)
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup("UpscViewportFocus", { clear = true })
  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "BufEnter", "WinEnter" }, {
    group = group,
    desc = "Keep the active file line twenty percent from the top",
    callback = function()
      M.place(vim.api.nvim_get_current_win())
    end,
  })
  vim.api.nvim_create_autocmd("WinScrolled", {
    group = group,
    desc = "Restore the active file line after viewport scrolling",
    callback = function(event)
      place_after_external_scroll(tonumber(event.match) or vim.api.nvim_get_current_win())
    end,
  })
  vim.api.nvim_create_autocmd("WinResized", {
    group = group,
    desc = "Reposition the active line after resizing windows",
    callback = function()
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        M.place(win)
      end
    end,
  })
  vim.api.nvim_create_autocmd("WinClosed", {
    group = group,
    callback = function(event)
      local win = tonumber(event.match)
      if win then
        last_views[win] = nil
        repositioning[win] = nil
      end
    end,
  })

  M.place(vim.api.nvim_get_current_win())
end

return M
