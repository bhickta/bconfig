local modules = {
  "upsc_notes.plugins.plenary",
  "upsc_notes.plugins.catppuccin",
  "upsc_notes.plugins.alpha",
  "upsc_notes.plugins.snacks",
  "upsc_notes.plugins.heirline",
  "upsc_notes.plugins.toggleterm",
  "upsc_notes.plugins.which-key",
  "upsc_notes.plugins.telescope",
  "upsc_notes.plugins.smart-splits",
  "upsc_notes.plugins.treesitter",
  "upsc_notes.plugins.render-markdown",
  "upsc_notes.plugins.neo-tree",
  "upsc_notes.plugins.obsidian",
}

local specs = {}

for _, module in ipairs(modules) do
  vim.list_extend(specs, require(module))
end

return specs
