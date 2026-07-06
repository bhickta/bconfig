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

local function current_tree_state(state)
  if state and state.tree then
    return state
  end

  local ok, current = pcall(require("neo-tree.sources.manager").get_state_for_window)
  if ok and current and current.tree then
    return current
  end
end

local function current_node(state)
  state = current_tree_state(state)
  if not state then
    vim.notify("Neo-tree is still loading. Try again after the tree redraws.", vim.log.levels.WARN)
    return nil, nil
  end

  local ok, node = pcall(state.tree.get_node, state.tree)
  if not ok or not node then
    vim.notify("Neo-tree has no focused node.", vim.log.levels.WARN)
    return nil, nil
  end

  return state, node
end

local function toggleterm_in_direction(state, direction)
  local node
  state, node = current_node(state)
  if not state then
    return
  end

  local path = node.type == "file" and node:get_parent_id() or node:get_id()
  require("toggleterm.terminal").Terminal:new({ dir = path, direction = direction }):toggle()
end

local function redraw_collapsed(state, focus_path)
  state = current_tree_state(state)
  if not state then
    return
  end

  local renderer = require("neo-tree.ui.renderer")
  state.explicitly_opened_nodes = {}
  state.force_open_folders = nil
  renderer.collapse_all_nodes(state.tree)
  renderer.redraw(state)
  renderer.focus_node(state, focus_path or state.path)
end

local function collapse_filtered_tree(state)
  if state.search_pattern and state.search_pattern ~= "" and state.tree then
    redraw_collapsed(state, state.path)
  end
end

local function toggle_filter(state)
  state = current_tree_state(state)
  if not state then
    return
  end

  local filesystem = require("neo-tree.sources.filesystem")
  if state.search_pattern and state.search_pattern ~= "" then
    state.upsc_saved_filter = state.search_pattern
    filesystem.reset_search(state, true)
    vim.notify("Tree filter off: " .. state.upsc_saved_filter, vim.log.levels.INFO)
    return
  end

  if not state.upsc_saved_filter or state.upsc_saved_filter == "" then
    vim.notify("No saved tree filter", vim.log.levels.WARN)
    return
  end

  state.search_pattern = state.upsc_saved_filter
  state.fuzzy_finder_mode = true
  state.open_folders_before_search = nil
  filesystem._navigate_internal(state, nil, nil, function()
    collapse_filtered_tree(state)
    vim.notify("Tree filter on: " .. state.search_pattern, vim.log.levels.INFO)
  end, false)
end

local function clear_filter(state)
  state = current_tree_state(state)
  if not state then
    return
  end

  state.upsc_saved_filter = nil
  require("neo-tree.sources.filesystem").reset_search(state, true)
  vim.notify("Tree filter cleared", vim.log.levels.INFO)
end

local function focus_folder(state)
  local node
  state, node = current_node(state)
  if not state then
    return
  end

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
  state = current_tree_state(state)
  if not state then
    return
  end

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
  local node
  state, node = current_node(state)
  if not state then
    return
  end

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

local function open_node_with_cmd(state, open_cmd)
  local node
  state, node = current_node(state)
  if not state then
    return
  end

  local utils = require("neo-tree.utils")
  local should_expand_file = state.config
    and state.config.expand_nested_files
    and node.type == "file"
    and not node:is_expanded()

  if utils.is_expandable(node) and (node.type ~= "file" or should_expand_file) then
    require("neo-tree.sources.filesystem").toggle_directory(state, node)
    return
  end

  local path = node.path or node:get_id()
  local bufnr = node.extra and node.extra.bufnr
  if node.type == "terminal" then
    path = node:get_id()
  end

  require("neo-tree.sources.common.commands").revert_preview()
  utils.open_file(state, path, open_cmd, bufnr)

  local extra = node.extra or {}
  local pos = extra.position or extra.end_position
  if pos then
    vim.api.nvim_win_set_cursor(0, { (pos[1] or 0) + 1, pos[2] or 0 })
    vim.api.nvim_win_call(0, function()
      vim.cmd("normal! zvzz")
    end)
  end
end

local function open_node(state)
  open_node_with_cmd(state, "e")
end

local function open_node_split(state)
  open_node_with_cmd(state, "split")
end

local function open_node_vsplit(state)
  open_node_with_cmd(state, "vsplit")
end

local function open_node_tabnew(state)
  open_node_with_cmd(state, "tabnew")
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
      open = open_node,
      open_split = open_node_split,
      open_vsplit = open_node_vsplit,
      open_tabnew = open_node_tabnew,
      system_open = function(state)
        local _, node = current_node(state)
        if node then
          vim.ui.open(node:get_id())
        end
      end,
      parent_or_close = function(state)
        local node
        state, node = current_node(state)
        if not state then
          return
        end

        if node:has_children() and node:is_expanded() then
          state.commands.toggle_node(state)
        else
          require("neo-tree.ui.renderer").focus_node(state, node:get_parent_id())
        end
      end,
      child_or_open = function(state)
        local node
        state, node = current_node(state)
        if not state then
          return
        end

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
        local node
        state, node = current_node(state)
        if not state then
          return
        end

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
      toggle_filter = toggle_filter,
      clear_filter = clear_filter,
    },
    filesystem = {
      bind_to_cwd = false,
      commands = {
        open = open_node,
        open_split = open_node_split,
        open_vsplit = open_node_vsplit,
        open_tabnew = open_node_tabnew,
      },
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
          ["/"] = {
            "fuzzy_finder",
            desc = "Filter tree",
            config = {
              keep_filter_on_submit = true,
              title = "Filter tree (persistent, <C-x> clears)",
            },
          },
          ["<C-x>"] = { "clear_filter", desc = "Clear tree filter" },
          tf = { "toggle_filter", desc = "Toggle tree filter" },
          ["."] = "focus_folder",
          [","] = "unfocus_folder",
          go = "open_folder_files",
        },
        fuzzy_finder_mappings = {
          ["<CR>"] = "close_keep_filter",
          ["<Esc>"] = "close_keep_filter",
          ["<C-x>"] = "close_clear_filter",
          {
            n = {
              ["<CR>"] = "close_keep_filter",
              ["<Esc>"] = "close_keep_filter",
              ["<C-x>"] = "close_clear_filter",
            },
          },
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
          vim.wo.statuscolumn = ""
          local ok, state = pcall(require("neo-tree.sources.manager").get_state_for_window)
          if ok and state then
            vim.schedule(function()
              collapse_filtered_tree(state)
            end)
          end
        end,
      },
    },
  }
end

return M
