package.path = vim.fn.getcwd() .. "/lua/?.lua;" .. vim.fn.getcwd() .. "/lua/?/init.lua;" .. package.path

require("upsc_notes.config").setup()
local reading_time = require("upsc_notes.reading_time")
local folder_time = require("upsc_notes.folder_reading_time")

local function assert_eq(actual, expected, message)
  if not vim.deep_equal(actual, expected) then
    error(("%s\nexpected: %s\nactual: %s"):format(message, vim.inspect(expected), vim.inspect(actual)), 2)
  end
end

local dir = vim.fn.tempname()
vim.fn.mkdir(dir, "p")
vim.fn.writefile({ "selected note is excluded" }, dir .. "/a.md")
vim.fn.writefile({ "one two" }, dir .. "/b.md")
vim.fn.writefile({ "three four five" }, dir .. "/c.md")
vim.fn.writefile({ "not a markdown note" }, dir .. "/ignored.txt")

reading_time.set_mode("xfast", { notify = false })
local midnight = os.time({ year = 2026, month = 1, day = 15, hour = 0, min = 0, sec = 0 })
local estimate = folder_time.estimate(dir .. "/a.md", midnight)
assert_eq(estimate.folder, vim.fs.basename(dir), "selected file determines the folder")
assert_eq(estimate.file_count, 2, "only Markdown files below the selection are counted")
assert_eq(estimate.words, 5, "selected and non-Markdown files are excluded")
assert_eq(estimate.minutes, 1, "folder reading time rounds up")
assert_eq(estimate.completed_at, "12:01 AM", "folder completion uses 12-hour time")

estimate = folder_time.estimate(dir .. "/b.md", midnight)
assert_eq(vim.tbl_map(vim.fs.basename, estimate.files), { "c.md" }, "only later sibling notes are included")
assert_eq(estimate.words, 3, "later note word count")

estimate = folder_time.estimate(dir .. "/c.md", midnight)
assert_eq(estimate.file_count, 0, "last selected file has no notes below it")
assert_eq(estimate.minutes, 0, "empty remainder takes zero minutes")

vim.fn.delete(dir, "rf")
