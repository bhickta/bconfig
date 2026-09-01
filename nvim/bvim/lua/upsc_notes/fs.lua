local M = {}

local uv = vim.uv or vim.loop

M.metadata_directories = {
  [".git"] = true,
  [".smart-env"] = true,
  [".trash"] = true,
}

local function stat_type(path)
  local stat = type(path) == "string" and path ~= "" and uv.fs_stat(path) or nil
  return stat and stat.type or nil
end

function M.is_directory(path)
  return stat_type(path) == "directory"
end

function M.is_file(path)
  return stat_type(path) == "file"
end

function M.is_within(root, path)
  if type(root) ~= "string" or root == "" or type(path) ~= "string" or path == "" then
    return false
  end

  root = vim.fs.normalize(root):gsub("/$", "")
  path = vim.fs.normalize(path):gsub("/$", "")
  return path == root or vim.startswith(path, root .. "/")
end

local function relative_path(root, path)
  local prefix = root .. "/"
  return vim.startswith(path, prefix) and path:sub(#prefix + 1) or vim.fs.basename(path)
end

function M.collect_files(root, opts)
  opts = opts or {}
  if type(root) ~= "string" or root == "" then
    return {}
  end
  root = vim.fs.normalize(vim.fn.fnamemodify(vim.fn.expand(root), ":p")):gsub("/$", "")
  if not M.is_directory(root) then
    return {}
  end

  local files = {}
  local include = opts.include or function() return true end
  local skipped_directories = opts.skipped_directories or {}

  local function scan(directory)
    local handle = uv.fs_scandir(directory)
    if not handle then
      return
    end

    while true do
      local name, kind = uv.fs_scandir_next(handle)
      if not name then
        break
      end

      local path = vim.fs.joinpath(directory, name)
      if kind == "file" and include(path, name) then
        table.insert(files, vim.fs.normalize(path))
      elseif kind == "directory" and opts.recursive and not skipped_directories[name] then
        scan(path)
      end
    end
  end

  scan(root)
  local compare = opts.compare or function(left, right)
    local left_relative = relative_path(root, left)
    local right_relative = relative_path(root, right)
    local left_folded = left_relative:lower()
    local right_folded = right_relative:lower()
    return left_folded == right_folded and left_relative < right_relative or left_folded < right_folded
  end
  table.sort(files, compare)
  return files
end

return M
