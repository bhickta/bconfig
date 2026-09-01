package.path = vim.fn.getcwd() .. "/lua/?.lua;" .. vim.fn.getcwd() .. "/lua/?/init.lua;" .. package.path

local history = require("upsc_notes.folder_history")

local function assert_eq(actual, expected, message)
  if not vim.deep_equal(actual, expected) then
    error(("%s\nexpected: %s\nactual: %s"):format(message, vim.inspect(expected), vim.inspect(actual)), 2)
  end
end

local temp = vim.fn.tempname()
local first_root = vim.fs.joinpath(temp, "first")
local second_root = vim.fs.joinpath(temp, "second")
local missing_root = vim.fs.joinpath(temp, "missing")
local state_file = vim.fs.joinpath(temp, "folder-history.json")
vim.fn.mkdir(first_root, "p")
vim.fn.mkdir(second_root, "p")
vim.g.upsc_folder_reader_state_file = state_file

vim.fn.writefile({
  vim.json.encode({
    [first_root] = { line = 10, column = 1, updated_at = 100 },
    [second_root] = { line = 20, column = 2, updated_at = 200 },
    [missing_root] = { line = 30, column = 3, updated_at = 300 },
  }),
}, state_file)

assert_eq(history.get(first_root).line, 10, "stored folder positions should be readable")
assert_eq(
  vim.tbl_map(function(entry) return entry.root end, history.recent()),
  { second_root, first_root },
  "recent folders should be ordered by recency and exclude deleted roots"
)
assert_eq(#history.recent(1), 1, "recent folder history should respect its limit")

assert_eq(history.save(first_root, { line = 40, column = 4 }), true, "folder history should save atomically")
assert_eq(history.get(first_root).line, 40, "saving should replace the selected folder position")
assert_eq(type(history.get(first_root).updated_at), "number", "saving should timestamp the folder entry")
assert_eq(history.get(second_root).line, 20, "saving one folder should preserve other folder entries")
assert_eq(vim.fn.glob(state_file .. ".*.tmp"), "", "atomic saves should not leave temporary files")

vim.fn.writefile({ "not json" }, state_file)
assert_eq(history.get(first_root), nil, "malformed state should degrade to an empty history")
assert_eq(history.recent(), {}, "malformed state should not break recent-folder listing")

vim.g.upsc_folder_reader_state_file = nil
vim.fn.delete(temp, "rf")
