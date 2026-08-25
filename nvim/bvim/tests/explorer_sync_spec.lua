package.path = vim.fn.getcwd() .. "/lua/?.lua;" .. vim.fn.getcwd() .. "/lua/?/init.lua;" .. package.path

local explorer_sync = require("upsc_notes.explorer_sync")

local original_schedule = vim.schedule
local original_manager = package.loaded["neo-tree.sources.manager"]
local original_command = package.loaded["neo-tree.command"]
local received

vim.schedule = function(callback) callback() end
package.loaded["neo-tree.sources.manager"] = {
  get_state = function()
    return { winid = vim.api.nvim_get_current_win(), current_position = "left" }
  end,
}
package.loaded["neo-tree.command"] = {
  execute = function(opts) received = opts end,
}

explorer_sync.reveal("/notes/topic/current.md")

if not received then
  error("an open explorer should sync to the focused file")
end
if received.action ~= "show" or received.source ~= "filesystem" then
  error("sync should update the filesystem explorer without taking editor focus")
end
if received.reveal_file ~= vim.fs.normalize("/notes/topic/current.md") then
  error("sync should reveal the focused file")
end
if received.reveal_force_cwd ~= true then
  error("sync should move an out-of-root explorer to the focused file's folder")
end

received = nil
package.loaded["neo-tree.sources.manager"] = nil
explorer_sync.reveal("/notes/topic/closed.md")
if received then
  error("sync should not open an explorer that the user closed")
end

vim.schedule = original_schedule
package.loaded["neo-tree.sources.manager"] = original_manager
package.loaded["neo-tree.command"] = original_command
