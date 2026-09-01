local M = {}

local uv = vim.uv or vim.loop
local default_recent_limit = 20

local function state_file()
  local override = vim.g.upsc_folder_reader_state_file
  if type(override) == "string" and override ~= "" then
    return vim.fs.normalize(vim.fn.expand(override))
  end
  return vim.fs.joinpath(vim.fn.stdpath("state"), "bvim-folder-reader-cursors.json")
end

local function read_entries()
  local ok, lines = pcall(vim.fn.readfile, state_file())
  if not ok or #lines == 0 then
    return {}
  end

  local decoded_ok, entries = pcall(vim.json.decode, table.concat(lines, "\n"))
  return decoded_ok and type(entries) == "table" and entries or {}
end

local function write_entries(entries)
  local encoded_ok, encoded = pcall(vim.json.encode, entries)
  if not encoded_ok then
    return false
  end

  local path = state_file()
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  local temporary_path = path .. "." .. uv.os_getpid() .. ".tmp"
  local write_ok, result = pcall(vim.fn.writefile, { encoded }, temporary_path)
  if not write_ok or result == -1 then
    vim.fn.delete(temporary_path)
    return false
  end

  local renamed = uv.fs_rename(temporary_path, path)
  if not renamed then
    vim.fn.delete(temporary_path)
    return false
  end
  return true
end

local function valid_root(root)
  if type(root) ~= "string" or root == "" then
    return false
  end
  local stat = uv.fs_stat(root)
  return stat and stat.type == "directory"
end

local function timestamp()
  local seconds, microseconds = uv.gettimeofday()
  return (seconds * 1000000) + microseconds
end

function M.get(root)
  local entry = type(root) == "string" and read_entries()[root] or nil
  return type(entry) == "table" and entry or nil
end

function M.save(root, position)
  if type(root) ~= "string" or root == "" or type(position) ~= "table" then
    return false
  end

  local entries = read_entries()
  local entry = vim.deepcopy(position)
  entry.updated_at = timestamp()
  entries[root] = entry
  return write_entries(entries)
end

function M.recent(limit)
  limit = math.max(0, math.floor(tonumber(limit) or default_recent_limit))
  local recent = {}

  for root, entry in pairs(read_entries()) do
    if type(entry) == "table" and valid_root(root) then
      table.insert(recent, {
        root = root,
        position = entry,
        updated_at = tonumber(entry.updated_at) or 0,
      })
    end
  end

  table.sort(recent, function(left, right)
    if left.updated_at == right.updated_at then
      return left.root:lower() < right.root:lower()
    end
    return left.updated_at > right.updated_at
  end)

  while #recent > limit do
    table.remove(recent)
  end
  return recent
end

return M
