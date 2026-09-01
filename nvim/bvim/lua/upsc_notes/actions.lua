local M = {}

local domains = {
  require("upsc_notes.actions.discovery"),
  require("upsc_notes.actions.buffers"),
  require("upsc_notes.actions.explorer"),
  require("upsc_notes.actions.reading"),
}

for _, domain in ipairs(domains) do
  for name, action in pairs(domain) do
    if M[name] ~= nil then
      error("upsc_notes.actions: duplicate action " .. name)
    end
    M[name] = action
  end
end

return M
