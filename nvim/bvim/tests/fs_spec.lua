package.path = vim.fn.getcwd() .. "/lua/?.lua;" .. vim.fn.getcwd() .. "/lua/?/init.lua;" .. package.path

local fs = require("upsc_notes.fs")

local function assert_eq(actual, expected, message)
  if not vim.deep_equal(actual, expected) then
    error(("%s\nexpected: %s\nactual: %s"):format(message, vim.inspect(expected), vim.inspect(actual)), 2)
  end
end

local root = vim.fn.tempname()
vim.fn.mkdir(vim.fs.joinpath(root, "nested"), "p")
vim.fn.mkdir(vim.fs.joinpath(root, ".git"), "p")
vim.fn.writefile({ "a" }, vim.fs.joinpath(root, "A.md"))
vim.fn.writefile({ "b" }, vim.fs.joinpath(root, "b.txt"))
vim.fn.writefile({ "c" }, vim.fs.joinpath(root, "nested", "c.MD"))
vim.fn.writefile({ "ignored" }, vim.fs.joinpath(root, ".git", "ignored.md"))

assert_eq(fs.is_directory(root), true, "directory detection")
assert_eq(fs.is_file(vim.fs.joinpath(root, "A.md")), true, "file detection")
assert_eq(fs.is_file(""), false, "empty paths are not files")
assert_eq(fs.is_within(root, root), true, "a root contains itself")
assert_eq(fs.is_within(root, vim.fs.joinpath(root, "nested", "c.MD")), true, "a root contains descendants")
assert_eq(fs.is_within(root, root .. "-other/file.md"), false, "path-prefix siblings are outside the root")

assert_eq(
  vim.tbl_map(function(path) return path:sub(#root + 2) end, fs.collect_files(root)),
  { "A.md", "b.txt" },
  "non-recursive collection should return only direct files"
)
assert_eq(
  vim.tbl_map(function(path) return path:sub(#root + 2) end, fs.collect_files(root, {
    recursive = true,
    skipped_directories = fs.metadata_directories,
    include = function(_, name) return name:lower():match("%.md$") ~= nil end,
  })),
  { "A.md", "nested/c.MD" },
  "recursive collection should filter files and skip metadata directories"
)
assert_eq(fs.collect_files(root .. "/missing"), {}, "missing roots should produce an empty collection")
assert_eq(fs.collect_files(nil), {}, "invalid roots should produce an empty collection")

vim.fn.delete(root, "rf")
