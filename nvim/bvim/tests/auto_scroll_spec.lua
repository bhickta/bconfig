package.path = vim.fn.getcwd() .. "/lua/?.lua;" .. vim.fn.getcwd() .. "/lua/?/init.lua;" .. package.path

require("upsc_notes.config").setup()
local reading_time = require("upsc_notes.reading_time")
local auto_scroll = require("upsc_notes.auto_scroll")

local function assert_eq(actual, expected, message)
  if actual ~= expected then
    error(("%s\nexpected: %s\nactual: %s"):format(message, vim.inspect(expected), vim.inspect(actual)), 2)
  end
end

reading_time.set_mode("slow", { notify = false })
assert_eq(auto_scroll.delay_for_line("one two three"), 1200, "slow speed line delay")

reading_time.set_mode("xfast", { notify = false })
assert_eq(auto_scroll.delay_for_line("one two three"), 360, "xfast line delay")
assert_eq(auto_scroll.delay_for_line(""), 50, "blank line delay")

local buf = vim.api.nvim_create_buf(false, false)
vim.api.nvim_set_current_buf(buf)
vim.bo[buf].filetype = "markdown"
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "one two three", "four five", "six" })

auto_scroll.start({ notify = false })
assert_eq(auto_scroll.is_active(buf), true, "auto-scroll starts for a Markdown note")
auto_scroll.stop({ notify = false })
assert_eq(auto_scroll.is_active(buf), false, "auto-scroll stops")

vim.api.nvim_buf_delete(buf, { force = true })
