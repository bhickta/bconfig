package.path = vim.fn.getcwd() .. "/lua/?.lua;" .. vim.fn.getcwd() .. "/lua/?/init.lua;" .. package.path

require("upsc_notes.config").setup()
local actions = require("upsc_notes.actions")
local expected = {
  "alternate_buffer", "apply_current_window_mode", "close_buffer", "close_other_buffers",
  "disable_study_mode", "dismiss_notifications", "enable_study_mode", "find_buffers", "find_commands",
  "find_folder_files", "find_headings", "find_in_note", "find_keymaps", "find_marks", "find_recent_files",
  "find_recent_scope_files", "find_scope_file", "find_undo", "find_zettel_note", "focus_tree",
  "focus_tree_panel", "grep_folder", "grep_in", "grep_scope", "grep_zettel", "jump_to_next_wikilink",
  "jump_to_prev_wikilink", "next_buffer", "open_dashboard", "open_in_dir", "open_in_tree", "open_vault_tree",
  "open_zettelkasten_dir", "open_zettel_tree", "prev_buffer", "read_focused_folder", "read_folder",
  "resume_picker", "reveal_current_note", "search_word", "set_edit_mode", "set_read_mode",
  "toggle_markdown_render", "toggle_read_edit_mode", "toggle_study_mode", "toggle_tree", "toggle_tree_focus",
  "toggle_zen", "unfocus_tree",
}

table.sort(expected)
local actual = vim.tbl_keys(actions)
table.sort(actual)
if not vim.deep_equal(actual, expected) then
  error(("public action API changed\nexpected: %s\nactual: %s"):format(vim.inspect(expected), vim.inspect(actual)))
end
for name, action in pairs(actions) do
  if type(action) ~= "function" then
    error(("action %s should be callable"):format(name))
  end
end
