local M = {}

local popup_win
local popup_buf
local request_token = 0
local cache = {}
local cache_order = {}
local max_cache_entries = 128
local endpoint = "https://html.duckduckgo.com/html/"

local function decode_html(text)
  text = text:gsub("<[^>]->", "")
  text = text:gsub("&#x(%x+);", function(value) return vim.fn.nr2char(tonumber(value, 16)) end)
  text = text:gsub("&#(%d+);", function(value) return vim.fn.nr2char(tonumber(value, 10)) end)
  local entities = {
    ["&amp;"] = "&",
    ["&quot;"] = '"',
    ["&apos;"] = "'",
    ["&lt;"] = "<",
    ["&gt;"] = ">",
    ["&nbsp;"] = " ",
  }
  return vim.trim((text:gsub("&[%a]+;", entities)):gsub("%s+", " "))
end

local function percent_decode(text)
  return (text:gsub("%%(%x%x)", function(value) return string.char(tonumber(value, 16)) end))
end

local function result_url(href)
  href = href:gsub("&amp;", "&")
  local encoded = href:match("[?&]uddg=([^&]+)")
  return encoded and percent_decode(encoded:gsub("+", " ")) or href
end

function M.parse_results(body, limit)
  local results = {}
  local snippets = {}
  for snippet in body:gmatch('class="result__snippet"[^>]*>(.-)</a>') do
    table.insert(snippets, decode_html(snippet))
  end
  for href, title in body:gmatch('class="result__a" href="(.-)">(.-)</a>') do
    table.insert(results, {
      title = decode_html(title),
      url = result_url(href),
      snippet = snippets[#results + 1] or "",
    })
    if #results >= (limit or 6) then
      break
    end
  end
  return results
end

function M.close()
  request_token = request_token + 1
  if popup_win and vim.api.nvim_win_is_valid(popup_win) then
    vim.api.nvim_win_close(popup_win, true)
  end
  popup_win = nil
  popup_buf = nil
end

local function show_lines(lines, title)
  if popup_win and vim.api.nvim_win_is_valid(popup_win) then
    vim.api.nvim_win_close(popup_win, true)
  end

  local max_width = math.max(20, math.min(92, vim.o.columns - 8))
  local width = 20
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
  vim.bo[popup_buf].filetype = "upsc-web-lookup"
  popup_win = vim.api.nvim_open_win(popup_buf, false, {
    relative = "cursor",
    row = 1,
    col = 0,
    width = width,
    height = math.min(height, math.max(1, vim.o.lines - 7)),
    style = "minimal",
    border = "rounded",
    title = " " .. title .. " ",
    title_pos = "center",
    focusable = false,
    noautocmd = true,
    zindex = 70,
  })
  vim.wo[popup_win].wrap = true
  vim.wo[popup_win].linebreak = true
  vim.wo[popup_win].winhl = "Normal:NormalFloat,FloatBorder:FloatBorder"
end

local function show_results(query, results)
  local lines = {}
  for index, result in ipairs(results) do
    table.insert(lines, ("%d. %s"):format(index, result.title))
    if result.snippet ~= "" then
      table.insert(lines, "   " .. result.snippet)
    end
    table.insert(lines, "   " .. result.url)
    if index < #results then
      table.insert(lines, "")
    end
  end
  show_lines(lines, "Web · " .. query)
end

local function query_from_context(opts)
  local query = opts and vim.trim(opts.args or "") or ""
  if query ~= "" then
    return query
  end

  local selection = require("upsc_notes.selection_translation")
  query = selection.current_selection()
  if query == "" and opts and opts.range and opts.range > 0 then
    query = selection.last_selection()
  end
  if query == "" then
    query = vim.fn.expand("<cword>")
  end
  return vim.trim(query:gsub("%s+", " "))
end

function M.search(opts)
  local query = query_from_context(opts)
  if query == "" then
    vim.notify("Select text or place the cursor on a word to search", vim.log.levels.WARN)
    return
  end
  if vim.fn.executable("curl") ~= 1 then
    vim.notify("Web lookup needs curl on PATH", vim.log.levels.ERROR)
    return
  end

  local cached = cache[query]
  if cached then
    show_results(query, cached)
    return
  end

  request_token = request_token + 1
  local current_request = request_token
  show_lines({ "Searching…" }, "Web · " .. query)
  vim.system({
    "curl",
    "--silent",
    "--show-error",
    "--fail",
    "--location",
    "--max-time",
    "10",
    "--user-agent",
    "Mozilla/5.0",
    "--get",
    "--data-urlencode",
    "q=" .. query,
    endpoint,
  }, { text = true }, function(response)
    vim.schedule(function()
      if current_request ~= request_token then
        return
      end
      if response.code ~= 0 then
        M.close()
        vim.notify("Web lookup failed: " .. vim.trim(response.stderr or "unknown error"), vim.log.levels.ERROR)
        return
      end

      local results = M.parse_results(response.stdout, 6)
      if #results == 0 then
        M.close()
        vim.notify("Web lookup returned no results", vim.log.levels.WARN)
        return
      end
      if #cache_order >= max_cache_entries then
        cache[table.remove(cache_order, 1)] = nil
      end
      cache[query] = results
      table.insert(cache_order, query)
      show_results(query, results)
    end)
  end)
end

function M.setup(group)
  vim.api.nvim_create_autocmd({ "BufLeave", "VimLeavePre" }, {
    group = group,
    desc = "Close the in-editor web lookup",
    callback = M.close,
  })
end

return M
