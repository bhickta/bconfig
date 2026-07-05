local actions = require("upsc_notes.actions")
local config = require("upsc_notes.config")
local paths = require("upsc_notes.paths")

local M = {}

local function create_command(name, rhs, opts)
  opts = vim.tbl_extend("force", { force = true }, opts or {})
  vim.api.nvim_create_user_command(name, rhs, opts)
end

function M.setup()
  create_command("Dashboard", actions.open_dashboard)
  create_command("FocusTree", actions.focus_tree)
  create_command("UnfocusTree", actions.unfocus_tree)

  create_command("Zettel", actions.find_zettel_note)
  create_command("In", actions.find_in_note)
  create_command("Ztree", actions.open_zettel_tree)
  create_command("InTree", actions.open_in_tree)
  create_command("RevealNote", actions.reveal_current_note)

  create_command("Zgrep", function(opts)
    if opts.args ~= "" then
      if vim.fn.executable("rg") ~= 1 then
        vim.notify("Content search needs ripgrep: install rg for live grep.", vim.log.levels.WARN)
        return
      end

      local ok, snacks = pcall(require, "snacks")
      if ok and snacks.picker then
        snacks.picker.grep(config.picker_defaults({
          cwd = paths.zettel_root,
          search = opts.args,
          title = "Grep zettelkasten",
          hidden = true,
          ignored = false,
        }))
        return
      end
    end

    actions.grep_zettel()
  end, { nargs = "*" })

  create_command("Ingrep", actions.grep_in)
  create_command("ScopeFiles", actions.find_scope_file)
  create_command("ScopeGrep", actions.grep_scope)
  create_command("PickerResume", actions.resume_picker)
  create_command("ReadMode", actions.set_read_mode)
  create_command("EditMode", actions.set_edit_mode)
  create_command("ToggleReadEdit", actions.toggle_read_edit_mode)
  create_command("StudyMode", actions.enable_study_mode)
  create_command("StudyModeOff", actions.disable_study_mode)
  create_command("ToggleStudyMode", actions.toggle_study_mode)
  create_command("MarkdownRenderToggle", actions.toggle_markdown_render)
end

return M
