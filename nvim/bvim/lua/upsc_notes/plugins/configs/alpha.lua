local icons = require("upsc_notes.astroui.icons")
local shortcuts = require("upsc_notes.shortcuts")

local M = {}

function M.setup()
  local alpha = require("alpha")
  local dashboard = require("alpha.themes.dashboard")

  dashboard.section.header.val = {
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

  dashboard.section.buttons.val = {}
  for _, shortcut in ipairs(shortcuts.dashboard_buttons(icons)) do
    table.insert(dashboard.section.buttons.val, dashboard.button(shortcut.key, shortcut.label, shortcut.command))
  end

  dashboard.section.footer.val = {
    "",
    shortcuts.dashboard_footer(),
  }

  dashboard.section.header.opts.hl = "UpscDashboardHeader"
  dashboard.section.header.opts.position = "center"
  dashboard.section.buttons.opts.hl = "UpscDashboardButton"
  dashboard.section.buttons.opts.position = "center"
  dashboard.section.footer.opts.hl = "UpscDashboardFooter"
  dashboard.section.footer.opts.position = "center"
  dashboard.opts.opts.noautocmd = true

  alpha.setup(dashboard.opts)
end

return M
