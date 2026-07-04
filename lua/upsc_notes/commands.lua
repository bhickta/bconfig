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
  require("telescope.builtin").live_grep({
    cwd = paths.zettel_root,
    default_text = opts.args,
    prompt_title = "Grep zettelkasten",
  })
end, { nargs = "*" })

vim.api.nvim_create_user_command("Waypoints", actions.find_waypoints, {})
vim.api.nvim_create_user_command("Zparent", actions.open_parent_waypoint, {})
vim.api.nvim_create_user_command("ReadMode", actions.set_read_mode, {})
vim.api.nvim_create_user_command("EditMode", actions.set_edit_mode, {})
vim.api.nvim_create_user_command("ToggleReadEdit", actions.toggle_read_edit_mode, {})
