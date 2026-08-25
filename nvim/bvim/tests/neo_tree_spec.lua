package.path = vim.fn.getcwd() .. "/lua/?.lua;" .. vim.fn.getcwd() .. "/lua/?/init.lua;" .. package.path

require("upsc_notes.config").setup()

local opts = require("upsc_notes.plugins.configs.neo-tree").opts()
local mappings = opts.filesystem.window.mappings

if mappings["."] ~= "focus_folder" then
  error("missing Neo-tree forward mapping: . -> focus_folder")
end

local expected = {
  ["<leader>fS"] = "find_folder_files",
  ["<leader>f/"] = "grep_folder",
}

for lhs, command in pairs(expected) do
  local mapping = mappings[lhs]
  if type(mapping) ~= "table" or mapping[1] ~= command then
    error(("missing Neo-tree folder search mapping: %s -> %s"):format(lhs, command))
  end
  if type(opts.commands[command]) ~= "function" then
    error("missing Neo-tree folder search command: " .. command)
  end
end

local captured = {}
package.loaded["upsc_notes.actions"] = {
  find_folder_files = function(dir)
    captured.files = dir
  end,
  grep_folder = function(dir)
    captured.grep = dir
  end,
}

local node = {
  type = "directory",
  get_id = function()
    return "/notes/active"
  end,
}
local state = {
  tree = {
    get_node = function()
      return node
    end,
  },
}

opts.commands.find_folder_files(state)
if captured.files ~= "/notes/active" then
  error("folder file search should use the selected directory")
end

node = {
  type = "file",
  get_parent_id = function()
    return "/notes/active/subfolder"
  end,
}
opts.commands.grep_folder(state)
if captured.grep ~= "/notes/active/subfolder" then
  error("folder grep should use a selected file's parent directory")
end

local opened = false
state.commands = {
  open = function(open_state)
    if open_state ~= state then
      error("forward should open the selected note with the current Neo-tree state")
    end
    opened = true
  end,
}
opts.commands.focus_folder(state)
if not opened then
  error("Neo-tree forward should open the highlighted note")
end

if opts.filesystem.follow_current_file.enabled ~= true or opts.filesystem.follow_current_file.leave_dirs_open ~= false then
  error("Neo-tree should reveal and focus the active file without leaving auto-opened directories behind")
end

local original_components = package.loaded["neo-tree.sources.common.components"]
package.loaded["neo-tree.sources.common.components"] = {
  icon = function()
    return { text = "file", highlight = "BaseIcon" }
  end,
  name = function()
    return { text = "note.md", highlight = "BaseName" }
  end,
}

vim.t.upsc_active_file = "/notes/active/note.md"
local active_node = {
  type = "file",
  path = "/notes/active/note.md",
}
local inactive_node = {
  type = "file",
  path = "/notes/active/other.md",
}

if opts.filesystem.components.name({}, active_node, {}).highlight ~= "UpscNeoTreeCurrentFile" then
  error("active file name should use the dedicated sidebar focus highlight")
end
if opts.filesystem.components.icon({}, active_node, {}).highlight ~= "UpscNeoTreeCurrentFile" then
  error("active file icon should use the dedicated sidebar focus highlight")
end
if opts.filesystem.components.name({}, inactive_node, {}).highlight ~= "BaseName" then
  error("inactive files should retain their normal Neo-tree highlight")
end

package.loaded["neo-tree.sources.common.components"] = original_components
