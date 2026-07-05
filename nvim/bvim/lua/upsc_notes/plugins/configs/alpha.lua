local icons = require("upsc_notes.astroui.icons")
local shortcuts = require("upsc_notes.shortcuts")

local M = {}

local function dashboard_width()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "alpha" then
      return vim.api.nvim_win_get_width(win)
    end
  end

  return vim.api.nvim_win_get_width(0)
end

local function narrow_dashboard()
  return dashboard_width() < 64
end

local function header()
  if narrow_dashboard() then
    return {
      "",
      "UPSC",
      "Zettelkasten | In | Vim",
      "",
    }
  end

  return {
    "",
    "██╗   ██╗██████╗ ███████╗ ██████╗",
    "██║   ██║██╔══██╗██╔════╝██╔════╝",
    "██║   ██║██████╔╝███████╗██║     ",
    "██║   ██║██╔═══╝ ╚════██║██║     ",
    "╚██████╔╝██║     ███████║╚██████╗",
    " ╚═════╝ ╚═╝     ╚══════╝ ╚═════╝",
    "",
    "Zettelkasten  •  In  •  Vim",
    "",
  }
end

local function button_label(shortcut)
  if not narrow_dashboard() then
    return shortcut.label
  end

  return shortcut.label:gsub("^%S+%s%s", "")
end

local function buttons(dashboard)
  local values = {}
  for _, shortcut in ipairs(shortcuts.dashboard_buttons(icons)) do
    local button = dashboard.button(shortcut.key, button_label(shortcut), shortcut.command)
    if narrow_dashboard() then
      button.opts.position = "left"
      button.opts.width = 24
    else
      button.opts.position = "center"
      button.opts.width = 50
    end
    table.insert(values, button)
  end
  return values
end

local function footer()
  if narrow_dashboard() then
    return { "", "f o recents | rr read/edit" }
  end

  return { "", shortcuts.dashboard_footer() }
end

function M.setup()
  local alpha = require("alpha")
  local dashboard = require("alpha.themes.dashboard")

  dashboard.section.header.val = header
  dashboard.section.buttons.val = function() return buttons(dashboard) end
  dashboard.section.footer.val = footer

  dashboard.section.header.opts.hl = "UpscDashboardHeader"
  dashboard.section.header.opts.position = "center"
  dashboard.section.buttons.opts.hl = "UpscDashboardButton"
  dashboard.section.buttons.opts.position = "center"
  dashboard.section.footer.opts.hl = "UpscDashboardFooter"
  dashboard.section.footer.opts.position = "center"
  dashboard.opts.opts.noautocmd = true
  dashboard.opts.opts.redraw_on_resize = true

  alpha.setup(dashboard.opts)
end

return M
