local M = {}

local generation = 0

function M.reveal(path)
  if type(path) ~= "string" or path == "" then
    return
  end

  generation = generation + 1
  local current_generation = generation
  path = vim.fs.normalize(path)

  vim.schedule(function()
    if current_generation ~= generation then
      return
    end

    local manager = package.loaded["neo-tree.sources.manager"]
    if not manager then
      return
    end

    local ok, state = pcall(manager.get_state, "filesystem")
    if not ok or not state or not state.winid or not vim.api.nvim_win_is_valid(state.winid) then
      return
    end

    local command_ok, command = pcall(require, "neo-tree.command")
    if not command_ok then
      return
    end

    command.execute({
      action = "show",
      source = "filesystem",
      position = state.current_position or "left",
      reveal_file = path,
      reveal_force_cwd = true,
    })
  end)
end

return M
