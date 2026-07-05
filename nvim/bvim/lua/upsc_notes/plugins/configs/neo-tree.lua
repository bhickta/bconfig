local icons = require("upsc_notes.astroui.icons")

local M = {}

local function collect_files(root)
  local files = {}
  local uv = vim.uv or vim.loop
  local skipped_dirs = {
    [".git"] = true,
    [".smart-env"] = true,
    [".trash"] = true,
  }

  local function scan(dir)
    local handle = uv.fs_scandir(dir)
    if not handle then
      return
    end

    while true do
      local name, kind = uv.fs_scandir_next(handle)
      if not name then
        break
      end

      local path = dir .. "/" .. name
      if kind == "file" then
        table.insert(files, path)
      elseif kind == "directory" and not skipped_dirs[name] then
        scan(path)
      end
    end
  end

  scan(root)
  table.sort(files)
  return files
end

local function toggleterm_in_direction(state, direction)
  local node = state.tree:get_node()
  local path = node.type == "file" and node:get_parent_id() or node:get_id()
  require("toggleterm.terminal").Terminal:new({ dir = path, direction = direction }):toggle()
end

local function redraw_collapsed(state, focus_path)
  local renderer = require("neo-tree.ui.renderer")
  state.explicitly_opened_nodes = {}
  state.force_open_folders = nil
  renderer.collapse_all_nodes(state.tree)
  renderer.redraw(state)
  renderer.focus_node(state, focus_path or state.path)
end

local function focus_folder(state)
  local node = state.tree:get_node()
  local path = node.type == "directory" and node:get_id() or node:get_parent_id()
  if not path or path == state.path then
    redraw_collapsed(state, path)
    return
  end

  local filesystem = require("neo-tree.sources.filesystem")
  if state.search_pattern then
    filesystem.reset_search(state, false)
  end
  state.explicitly_opened_nodes = {}
  state.force_open_folders = nil
  filesystem._navigate_internal(state, path, nil, function()
    redraw_collapsed(state, path)
  end, false)
end

local function unfocus_folder(state)
  local parent_path = require("neo-tree.utils").split_path(state.path)
  if not parent_path or parent_path == state.path then
    redraw_collapsed(state, state.path)
    return
  end

  local filesystem = require("neo-tree.sources.filesystem")
  if state.search_pattern then
    filesystem.reset_search(state, false)
  end

  state.explicitly_opened_nodes = {}
  state.force_open_folders = nil
  filesystem._navigate_internal(state, parent_path, nil, function()
    redraw_collapsed(state, parent_path)
  end, false)
end

local function open_folder_files(state)
  local node = state.tree:get_node()
  local dir = node.type == "directory" and node:get_id() or node:get_parent_id()
  local files = collect_files(dir)

  if #files == 0 then
    vim.notify("No files found in folder: " .. dir, vim.log.levels.WARN)
    return
  end

  local utils = require("neo-tree.utils")
  for _, file in ipairs(files) do
    vim.cmd.badd(vim.fn.fnameescape(file))
  end
  utils.open_file(state, files[1])
  vim.notify(("Opened %d files from folder"):format(#files), vim.log.levels.INFO)
end

function M.opts()
  local git_available = vim.fn.executable("git") == 1
  local sources = {
    { source = "filesystem", display_name = icons.tree.file },
    { source = "buffers", display_name = icons.tree.buffers },
  }

  if git_available then
    table.insert(sources, 3, { source = "git_status", display_name = icons.tree.git })
  end

  return {
    enable_git_status = git_available,
    auto_clean_after_session_restore = true,
    close_if_last_window = true,
    popup_border_style = "",
    sources = { "filesystem", "buffers", git_available and "git_status" or nil },
    source_selector = {
      winbar = true,
      content_layout = "center",
      sources = sources,
    },
    default_component_configs = {
      indent = {
        padding = 0,
        expander_collapsed = icons.tree.collapsed,
        expander_expanded = icons.tree.expanded,
      },
      icon = {
        folder_closed = icons.tree.folder_closed,
        folder_open = icons.tree.folder_open,
        folder_empty = icons.tree.folder_empty,
        folder_empty_open = icons.tree.folder_empty,
        default = icons.tree.file_default,
      },
      modified = {
        symbol = icons.tree.modified,
      },
      git_status = {
        symbols = {
          added = icons.git.added,
          deleted = icons.git.deleted,
          modified = icons.git.modified,
          renamed = icons.git.renamed,
          untracked = icons.git.untracked,
          ignored = icons.git.ignored,
          unstaged = icons.git.unstaged,
          staged = icons.git.staged,
          conflict = icons.git.conflict,
        },
      },
    },
    commands = {
      system_open = function(state)
        vim.ui.open(state.tree:get_node():get_id())
      end,
      parent_or_close = function(state)
        local node = state.tree:get_node()
        if node:has_children() and node:is_expanded() then
          state.commands.toggle_node(state)
        else
          require("neo-tree.ui.renderer").focus_node(state, node:get_parent_id())
        end
      end,
      child_or_open = function(state)
        local node = state.tree:get_node()
        if node:has_children() then
          if not node:is_expanded() then
            state.commands.toggle_node(state)
          elseif node.type == "file" then
            state.commands.open(state)
          else
            require("neo-tree.ui.renderer").focus_node(state, node:get_child_ids()[1])
          end
        else
          state.commands.open(state)
        end
      end,
      copy_selector = function(state)
        local node = state.tree:get_node()
        local filepath = node:get_id()
        local filename = node.name
        local modify = vim.fn.fnamemodify
        local vals = {
          ["BASENAME"] = modify(filename, ":r"),
          ["EXTENSION"] = modify(filename, ":e"),
          ["FILENAME"] = filename,
          ["PATH (CWD)"] = modify(filepath, ":."),
          ["PATH (HOME)"] = modify(filepath, ":~"),
          ["PATH"] = filepath,
          ["URI"] = vim.uri_from_fname(filepath),
        }
        local options = vim.tbl_filter(function(val)
          return vals[val] ~= ""
        end, vim.tbl_keys(vals))

        table.sort(options)
        vim.ui.select(options, {
          prompt = "Choose to copy to clipboard:",
          format_item = function(item)
            return ("%s: %s"):format(item, vals[item])
          end,
        }, function(choice)
          local result = vals[choice]
          if result then
            vim.fn.setreg("+", result)
            vim.notify(("Copied: `%s`"):format(result), vim.log.levels.INFO)
          end
        end)
      end,
      toggleterm_float = function(state)
        toggleterm_in_direction(state, "float")
      end,
      toggleterm_horizontal = function(state)
        toggleterm_in_direction(state, "horizontal")
      end,
      toggleterm_vertical = function(state)
        toggleterm_in_direction(state, "vertical")
      end,
      open_folder_files = open_folder_files,
      focus_folder = focus_folder,
      unfocus_folder = unfocus_folder,
    },
    filesystem = {
      bind_to_cwd = false,
      follow_current_file = { enabled = true },
      filtered_items = {
        visible = true,
        hide_dotfiles = false,
        hide_gitignored = git_available,
        hide_by_name = {
          ".git",
          ".smart-env",
          ".trash",
        },
      },
      group_empty_dirs = false,
      hijack_netrw_behavior = "open_current",
      use_libuv_file_watcher = vim.fn.has("win32") ~= 1,
      window = {
        mappings = {
          ["."] = "focus_folder",
          [","] = "unfocus_folder",
          go = "open_folder_files",
        },
      },
    },
    window = {
      width = 30,
      mappings = {
        ["<S-CR>"] = "system_open",
        ["<space>"] = false,
        ["[b"] = "prev_source",
        ["]b"] = "next_source",
        O = "system_open",
        T = { "show_help", nowait = false, config = { title = "Terminal", prefix_key = "T" } },
        Tf = "toggleterm_float",
        Th = "toggleterm_horizontal",
        Tv = "toggleterm_vertical",
        Y = "copy_selector",
        h = "parent_or_close",
        l = "child_or_open",
      },
      fuzzy_finder_mappings = {
        ["<C-J>"] = "move_cursor_down",
        ["<C-K>"] = "move_cursor_up",
      },
    },
    event_handlers = {
      {
        event = "neo_tree_buffer_enter",
        handler = function()
          vim.opt_local.signcolumn = "auto"
          vim.opt_local.foldcolumn = "0"
          vim.wo.wrap = true
          vim.wo.linebreak = true
          vim.wo.sidescrolloff = 0
        end,
      },
    },
  }
end

return M
