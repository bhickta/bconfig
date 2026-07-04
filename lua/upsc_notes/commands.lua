local actions = require("upsc_notes.actions")
local paths = require("upsc_notes.paths")

vim.api.nvim_create_user_command("Dashboard", actions.open_dashboard, {})
vim.api.nvim_create_user_command("FocusTree", actions.focus_tree, {})
vim.api.nvim_create_user_command("UnfocusTree", actions.unfocus_tree, {})

vim.api.nvim_create_user_command("Zettel", actions.find_zettel_note, {})
vim.api.nvim_create_user_command("In", actions.find_in_note, {})
vim.api.nvim_create_user_command("Ztree", actions.open_zettel_tree, {})
vim.api.nvim_create_user_command("InTree", actions.open_in_tree, {})
vim.api.nvim_create_user_command("RevealNote", actions.reveal_current_note, {})

vim.api.nvim_create_user_command("Zgrep", function(opts)
  if opts.args ~= "" then
    if vim.fn.executable("rg") ~= 1 then
      vim.notify("Content search needs ripgrep: install rg for live grep.", vim.log.levels.WARN)
      return
    end

    local ok, snacks = pcall(require, "snacks")
    if ok and snacks.picker then
      snacks.picker.grep({
        cwd = paths.zettel_root,
        search = opts.args,
        title = "Grep zettelkasten",
        hidden = true,
        ignored = false,
        matcher = {
          fuzzy = true,
          smartcase = true,
          ignorecase = true,
          sort_empty = false,
          filename_bonus = true,
          file_pos = true,
          cwd_bonus = true,
        },
        sort = {
          fields = { "score:desc", "#text", "idx" },
        },
        debug = {},
      })
      return
    end
  end

  actions.grep_zettel()
end, { nargs = "*" })

vim.api.nvim_create_user_command("Ingrep", actions.grep_in, {})
vim.api.nvim_create_user_command("ScopeFiles", actions.find_scope_file, {})
vim.api.nvim_create_user_command("ScopeGrep", actions.grep_scope, {})
vim.api.nvim_create_user_command("PickerResume", actions.resume_picker, {})
vim.api.nvim_create_user_command("ReadMode", actions.set_read_mode, {})
vim.api.nvim_create_user_command("EditMode", actions.set_edit_mode, {})
vim.api.nvim_create_user_command("ToggleReadEdit", actions.toggle_read_edit_mode, {})
vim.api.nvim_create_user_command("StudyMode", actions.enable_study_mode, {})
vim.api.nvim_create_user_command("StudyModeOff", actions.disable_study_mode, {})
vim.api.nvim_create_user_command("ToggleStudyMode", actions.toggle_study_mode, {})
vim.api.nvim_create_user_command("MarkdownRenderToggle", actions.toggle_markdown_render, {})
