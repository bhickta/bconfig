local expected_commands = {
  "Dashboard",
  "FocusTree",
  "UnfocusTree",
  "Zettel",
  "In",
  "Ztree",
  "InTree",
  "RevealNote",
  "Zgrep",
  "Ingrep",
  "ScopeFiles",
  "ScopeGrep",
  "PickerResume",
  "ReadMode",
  "EditMode",
  "ToggleReadEdit",
  "StudyMode",
  "StudyModeOff",
  "ToggleStudyMode",
  "MarkdownRenderToggle",
}

for _, command in ipairs(expected_commands) do
  if vim.fn.exists(":" .. command) ~= 2 then
    error("missing command: " .. command)
  end
end

local config = require("upsc_notes.config").get()
if config.paths.vault_root == "" or config.paths.zettel_root == "" or config.paths.in_root == "" then
  error("config paths should be populated")
end
