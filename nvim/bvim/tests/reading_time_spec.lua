package.path = vim.fn.getcwd() .. "/lua/?.lua;" .. vim.fn.getcwd() .. "/lua/?/init.lua;" .. package.path

require("upsc_notes.config").setup()
local reading_time = require("upsc_notes.reading_time")

local function assert_eq(actual, expected, message)
  if actual ~= expected then
    error(("%s\nexpected: %s\nactual: %s"):format(message, vim.inspect(expected), vim.inspect(actual)), 2)
  end
end

local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { table.concat(vim.fn.map(vim.fn.range(1, 501), '"word"'), " ") })

reading_time.set_mode("xfast", { notify = false })
local midnight = os.time({ year = 2026, month = 1, day = 15, hour = 0, min = 0, sec = 0 })
local estimate = reading_time.estimate(buf, midnight)
assert_eq(estimate.words, 501, "word count")
assert_eq(estimate.minutes, 2, "xfast estimate rounds up")
assert_eq(estimate.completed_at, "12:02 AM", "12-hour completion time")

vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "one two three" })
assert_eq(reading_time.estimate(buf, midnight).words, 3, "word count refreshes after edits")

vim.api.nvim_buf_set_lines(buf, 0, -1, false, { table.concat(vim.fn.map(vim.fn.range(1, 501), '"word"'), " ") })

reading_time.set_mode("slow", { notify = false })
assert_eq(reading_time.estimate(buf, 0).minutes, 4, "slow estimate")

reading_time.cycle_mode({ notify = false })
assert_eq(reading_time.get_mode(), "medium", "mode cycle")

local ok = pcall(reading_time.set_mode, "warp", { notify = false })
assert_eq(ok, false, "invalid modes are rejected")

vim.api.nvim_buf_delete(buf, { force = true })
