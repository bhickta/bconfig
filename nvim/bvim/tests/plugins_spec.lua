package.path = vim.fn.getcwd() .. "/lua/?.lua;" .. vim.fn.getcwd() .. "/lua/?/init.lua;" .. package.path

require("upsc_notes.config").setup()

local specs = require("upsc_notes.plugins")

if type(specs) ~= "table" or #specs == 0 then
  error("plugin specs should be a non-empty list")
end

local seen = {}

for _, spec in ipairs(specs) do
  if type(spec) ~= "table" then
    error("plugin spec should be a table")
  end

  local name = spec[1] or spec.name
  if type(name) ~= "string" or name == "" then
    error("plugin spec should expose a repository/name")
  end

  if seen[name] then
    error("duplicate plugin spec: " .. name)
  end

  seen[name] = true
end
