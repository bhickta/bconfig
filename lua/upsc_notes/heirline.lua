local M = {}

local colors = {
  bg = "#11111b",
  bg_alt = "#181825",
  bg_line = "#313244",
  fg = "#cdd6f4",
  muted = "#6c7086",
  subtle = "#9399b2",
  border = "#45475a",
  blue = "#89b4fa",
  cyan = "#89dceb",
  green = "#a6e3a1",
  mauve = "#cba6f7",
  peach = "#fab387",
  red = "#f38ba8",
  yellow = "#f9e2af",
}

local align = { provider = "%=" }
local space = { provider = " " }

local function is_real_file(buf)
  return vim.bo[buf].buftype == "" and vim.api.nvim_buf_get_name(buf) ~= ""
end

local mode = {
  provider = function()
    return " " .. vim.api.nvim_get_mode().mode:upper() .. " "
  end,
  hl = { fg = colors.bg, bg = colors.blue, bold = true },
  update = {
    "ModeChanged",
    pattern = "*:*",
    callback = vim.schedule_wrap(function() vim.cmd.redrawstatus() end),
  },
}

local file = {
  provider = function()
    local name = vim.api.nvim_buf_get_name(0)
    if name == "" then
      return "[No Name]"
    end
    return vim.fn.fnamemodify(name, ":~:.")
  end,
  hl = { fg = colors.fg, bg = colors.bg_alt },
}

local modified = {
  condition = function() return vim.bo.modified end,
  provider = " +",
  hl = { fg = colors.yellow, bg = colors.bg_alt },
}

local readonly = {
  condition = function() return vim.bo.readonly or not vim.bo.modifiable end,
  provider = " ro",
  hl = { fg = colors.red, bg = colors.bg_alt },
}

local git_branch = {
  condition = function()
    return vim.b.gitsigns_head ~= nil and vim.b.gitsigns_head ~= ""
  end,
  provider = function()
    return " " .. vim.b.gitsigns_head .. " "
  end,
  hl = { fg = colors.mauve, bg = colors.bg_alt },
}

local diagnostics = {
  condition = function()
    return #vim.diagnostic.get(0) > 0
  end,
  provider = function()
    local counts = vim.diagnostic.count(0)
    local out = {}
    local severity = vim.diagnostic.severity
    if counts[severity.ERROR] then
      table.insert(out, "E" .. counts[severity.ERROR])
    end
    if counts[severity.WARN] then
      table.insert(out, "W" .. counts[severity.WARN])
    end
    if counts[severity.INFO] then
      table.insert(out, "I" .. counts[severity.INFO])
    end
    if counts[severity.HINT] then
      table.insert(out, "H" .. counts[severity.HINT])
    end
    return " " .. table.concat(out, " ") .. " "
  end,
  hl = { fg = colors.yellow, bg = colors.bg_alt },
  update = { "DiagnosticChanged", "BufEnter" },
}

local filetype = {
  provider = function()
    return vim.bo.filetype ~= "" and (" " .. vim.bo.filetype .. " ") or ""
  end,
  hl = { fg = colors.cyan, bg = colors.bg_alt },
}

local location = {
  provider = " %l:%c ",
  hl = { fg = colors.peach, bg = colors.bg_alt },
}

local progress = {
  provider = " %P ",
  hl = { fg = colors.green, bg = colors.bg_alt },
}

local bufferline = {
  condition = function()
    return #vim.fn.getbufinfo({ buflisted = 1 }) > 1
  end,
  provider = function()
    local active = vim.api.nvim_get_current_buf()
    local parts = {}
    for _, buf in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
      if is_real_file(buf.bufnr) then
        local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf.bufnr), ":t")
        local marker = vim.bo[buf.bufnr].modified and "+" or ""
        if buf.bufnr == active then
          table.insert(parts, "[ " .. name .. marker .. " ]")
        else
          table.insert(parts, " " .. name .. marker .. " ")
        end
      end
    end
    return table.concat(parts, " ")
  end,
  hl = { fg = colors.subtle, bg = colors.bg_alt },
}

local winbar = {
  condition = function()
    local ft = vim.bo.filetype
    return ft ~= "neo-tree" and ft ~= "alpha" and vim.bo.buftype == ""
  end,
  hl = { fg = colors.subtle, bg = colors.bg },
  {
    provider = function()
      local name = vim.api.nvim_buf_get_name(0)
      if name == "" then
        return ""
      end
      local dir = vim.fn.fnamemodify(name, ":~:.:h")
      local tail = vim.fn.fnamemodify(name, ":t")
      if dir == "." or dir == "" then
        return " " .. tail .. " "
      end
      return " " .. dir .. " / " .. tail .. " "
    end,
  },
}

local statuscolumn = {
  {
    provider = function()
      if vim.v.virtnum ~= 0 then
        return "%="
      end
      if vim.v.relnum == 0 then
        return "%#CursorLineNr#%l "
      end
      return "%#LineNr#%r "
    end,
  },
  {
    provider = "%s",
  },
  {
    provider = "%C",
  },
}

function M.setup()
  require("heirline").setup({
    statusline = {
      hl = { fg = colors.fg, bg = colors.bg_alt },
      mode,
      git_branch,
      space,
      file,
      modified,
      readonly,
      diagnostics,
      align,
      filetype,
      location,
      progress,
    },
    winbar = winbar,
    tabline = bufferline,
    statuscolumn = statuscolumn,
  })
end

return M
