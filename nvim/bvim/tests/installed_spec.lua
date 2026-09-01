local expected_commands = {
  "Dashboard",
  "FocusTree",
  "RevealNote",
  "ToggleReadEdit",
}

for _, command in ipairs(expected_commands) do
  if vim.fn.exists(":" .. command) ~= 2 then
    error("missing installed command: " .. command)
  end
end

local expected_shortcuts = {
  n = {
    ["<C-lt>"] = "Move to left split",
    ["<C->>"] = "Move to right split",
  },
  t = {
    ["<C-lt>"] = "Move to left split",
    ["<C->>"] = "Move to right split",
  },
}

for mode, shortcuts in pairs(expected_shortcuts) do
  for lhs, description in pairs(shortcuts) do
    local mapping = vim.fn.maparg(lhs, mode, false, true)
    if mapping.desc ~= description then
      error(("missing installed shortcut: %s %s (%s)"):format(mode, lhs, description))
    end
  end
end
