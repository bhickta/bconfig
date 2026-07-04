local M = {}

local colors = {
  bg = "#11111b",
  bg_alt = "#181825",
  bg_float = "#1e1e2e",
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

local function set(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

function M.apply()
  set("Normal", { fg = colors.fg, bg = colors.bg })
  set("NormalFloat", { fg = colors.fg, bg = colors.bg_float })
  set("FloatBorder", { fg = colors.border, bg = colors.bg_float })
  set("FloatTitle", { fg = colors.blue, bg = colors.bg_float, bold = true })
  set("CursorLine", { bg = colors.bg_line })
  set("Visual", { bg = "#3b4261" })
  set("Search", { fg = colors.bg, bg = colors.yellow, bold = true })
  set("IncSearch", { fg = colors.bg, bg = colors.peach, bold = true })
  set("Pmenu", { fg = colors.fg, bg = colors.bg_float })
  set("PmenuSel", { fg = colors.bg, bg = colors.blue, bold = true })

  set("UpscDashboardHeader", { fg = colors.blue, bold = true })
  set("UpscDashboardButton", { fg = colors.fg })
  set("UpscDashboardShortcut", { fg = colors.peach, bold = true })
  set("UpscDashboardFooter", { fg = colors.muted })

  set("SnacksPicker", { fg = colors.fg, bg = colors.bg_float })
  set("SnacksPickerBorder", { fg = colors.border, bg = colors.bg_float })
  set("SnacksPickerTitle", { fg = colors.blue, bg = colors.bg_float, bold = true })
  set("SnacksPickerBoxBorder", { fg = colors.border, bg = colors.bg_float })
  set("SnacksPickerInput", { fg = colors.fg, bg = colors.bg_alt })
  set("SnacksPickerInputBorder", { fg = colors.blue, bg = colors.bg_alt })
  set("SnacksPickerPrompt", { fg = colors.peach, bg = colors.bg_alt, bold = true })
  set("SnacksPickerInputSearch", { fg = colors.yellow, bg = colors.bg_alt, bold = true })
  set("SnacksPickerList", { fg = colors.fg, bg = colors.bg_float })
  set("SnacksPickerListBorder", { fg = colors.border, bg = colors.bg_float })
  set("SnacksPickerListCursorLine", { fg = colors.fg, bg = colors.bg_line })
  set("SnacksPickerPreview", { fg = colors.fg, bg = colors.bg })
  set("SnacksPickerPreviewBorder", { fg = colors.border, bg = colors.bg })
  set("SnacksPickerPreviewCursorLine", { bg = colors.bg_line })
  set("SnacksPickerMatch", { fg = colors.peach, bold = true })
  set("SnacksPickerSearch", { fg = colors.bg, bg = colors.yellow, bold = true })
  set("SnacksPickerDir", { fg = colors.muted })
  set("SnacksPickerDirectory", { fg = colors.blue, bold = true })
  set("SnacksPickerFile", { fg = colors.fg })
  set("SnacksPickerPathHidden", { fg = colors.muted })
  set("SnacksPickerPathIgnored", { fg = colors.muted })
  set("SnacksPickerRow", { fg = colors.green })
  set("SnacksPickerCol", { fg = colors.subtle })
  set("SnacksPickerDelim", { fg = colors.muted })
  set("SnacksPickerTotals", { fg = colors.subtle })
  set("SnacksPickerComment", { fg = colors.muted, italic = true })
  set("SnacksPickerSelected", { fg = colors.green, bold = true })
  set("SnacksPickerUnselected", { fg = colors.muted })
  set("SnacksPickerSpinner", { fg = colors.peach })
  set("SnacksPickerPickWin", { fg = colors.bg, bg = colors.peach, bold = true })
  set("SnacksPickerPickWinCurrent", { fg = colors.bg, bg = colors.green, bold = true })

  set("NeoTreeNormal", { fg = colors.fg, bg = colors.bg_alt })
  set("NeoTreeNormalNC", { fg = colors.fg, bg = colors.bg_alt })
  set("NeoTreeWinSeparator", { fg = colors.border, bg = colors.bg_alt })
  set("NeoTreeDirectoryName", { fg = colors.blue, bold = true })
  set("NeoTreeDirectoryIcon", { fg = colors.blue })
  set("NeoTreeFileName", { fg = colors.fg })
  set("NeoTreeFileNameOpened", { fg = colors.peach, bold = true })
  set("NeoTreeCursorLine", { bg = colors.bg_line })
  set("NeoTreeRootName", { fg = colors.mauve, bold = true })

  set("WhichKeyFloat", { bg = colors.bg_float })
  set("WhichKeyBorder", { fg = colors.border, bg = colors.bg_float })
  set("WhichKey", { fg = colors.blue })
  set("WhichKeyGroup", { fg = colors.mauve })
  set("WhichKeyDesc", { fg = colors.fg })
end

function M.setup()
  local group = vim.api.nvim_create_augroup("UpscNotesUi", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = M.apply,
  })
  M.apply()
end

return M
