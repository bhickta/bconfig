local actions = require("upsc_notes.actions")
local paths = require("upsc_notes.paths")

vim.api.nvim_create_user_command("Dashboard", actions.open_dashboard, {})
vim.api.nvim_create_user_command("Ethics", actions.open_ethics, {})
vim.api.nvim_create_user_command("Polity", actions.open_polity, {})
vim.api.nvim_create_user_command("FocusTree", actions.focus_tree, {})
vim.api.nvim_create_user_command("UnfocusTree", actions.unfocus_tree, {})

vim.api.nvim_create_user_command("Vault", function()
  vim.cmd("cd " .. vim.fn.fnameescape(paths.vault_root))
  actions.open_dashboard()
end, {})

vim.api.nvim_create_user_command("Zettel", actions.find_zettel_note, {})
vim.api.nvim_create_user_command("VaultTree", actions.open_vault_tree, {})
vim.api.nvim_create_user_command("Ztree", actions.open_zettel_tree, {})
vim.api.nvim_create_user_command("RevealNote", actions.reveal_current_note, {})

vim.api.nvim_create_user_command("Zgrep", function(opts)
  if opts.args ~= "" then
    local ok, snacks = pcall(require, "snacks")
    if ok and snacks.picker then
      snacks.picker.grep({ cwd = paths.zettel_root, search = opts.args, title = "Grep zettelkasten" })
      return
    end
  end

  actions.grep_zettel()
end, { nargs = "*" })

vim.api.nvim_create_user_command("Waypoints", actions.find_waypoints, {})
vim.api.nvim_create_user_command("ScopeFiles", actions.find_scope_file, {})
vim.api.nvim_create_user_command("ScopeGrep", actions.grep_scope, {})
vim.api.nvim_create_user_command("RecentNotes", actions.recent_notes, {})
vim.api.nvim_create_user_command("PickerResume", actions.resume_picker, {})
vim.api.nvim_create_user_command("Zparent", actions.open_parent_waypoint, {})
vim.api.nvim_create_user_command("ReadMode", actions.set_read_mode, {})
vim.api.nvim_create_user_command("EditMode", actions.set_edit_mode, {})
vim.api.nvim_create_user_command("ToggleReadEdit", actions.toggle_read_edit_mode, {})
