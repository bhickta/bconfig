package.path = vim.fn.getcwd() .. "/lua/?.lua;" .. vim.fn.getcwd() .. "/lua/?/init.lua;" .. package.path

require("upsc_notes.config").setup()
local reading_time = require("upsc_notes.reading_time")
local auto_scroll = require("upsc_notes.auto_scroll")
auto_scroll.setup()

local function assert_eq(actual, expected, message)
  if actual ~= expected then
    error(("%s\nexpected: %s\nactual: %s"):format(message, vim.inspect(expected), vim.inspect(actual)), 2)
  end
end

reading_time.set_mode("slow", { notify = false })
assert_eq(auto_scroll.delay_for_line("one two three"), 1200, "slow speed line delay")

reading_time.set_mode("xslow", { notify = false })
assert_eq(auto_scroll.delay_for_line("one two three"), 1800, "xslow line delay")

reading_time.set_mode("xxslow", { notify = false })
assert_eq(auto_scroll.delay_for_line("one two three"), 3000, "xxslow line delay")

reading_time.set_mode("xfast", { notify = false })
assert_eq(auto_scroll.delay_for_line("one two three"), 360, "xfast line delay")
assert_eq(auto_scroll.delay_for_line(""), 50, "blank line delay")

local buf = vim.api.nvim_create_buf(false, false)
vim.api.nvim_set_current_buf(buf)
vim.bo[buf].filetype = "markdown"
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "one two three", "four five", "six" })

local original_defer_fn = vim.defer_fn
local deferred = {}
vim.defer_fn = function(callback, delay)
  table.insert(deferred, { callback = callback, delay = delay })
end

vim.api.nvim_win_set_cursor(0, { 3, 0 })
auto_scroll.start({ notify = false })
assert_eq(auto_scroll.is_active(buf), true, "auto-scroll starts for a Markdown note")
assert_eq(vim.api.nvim_win_get_cursor(0)[1], 3, "auto-scroll starts from the cursor position")
assert_eq(deferred[#deferred].delay, 120, "the initial delay uses the cursor line")

local pending_before_pause = deferred[#deferred]
assert_eq(auto_scroll.pause({ notify = false }), true, "running auto-scroll can be paused")
assert_eq(auto_scroll.is_active(buf), false, "paused auto-scroll is not active")
assert_eq(auto_scroll.is_paused(buf), true, "paused auto-scroll retains its session")
pending_before_pause.callback()
assert_eq(vim.api.nvim_win_get_cursor(0)[1], 3, "a cancelled timer cannot move the cursor while paused")
assert_eq(auto_scroll.resume({ notify = false }), true, "paused auto-scroll can resume")
assert_eq(auto_scroll.is_active(buf), true, "resumed auto-scroll is active")
assert_eq(auto_scroll.is_paused(buf), false, "resumed auto-scroll is no longer paused")
assert_eq(vim.api.nvim_win_get_cursor(0)[1], 3, "resume continues from the paused cursor position")
auto_scroll.toggle()
assert_eq(auto_scroll.is_paused(buf), true, "the auto-scroll shortcut pauses a running reader")
auto_scroll.toggle()
assert_eq(auto_scroll.is_active(buf), true, "the auto-scroll shortcut resumes a paused reader")

local scheduled_before_move = #deferred
vim.api.nvim_win_set_cursor(0, { 2, 0 })
vim.api.nvim_exec_autocmds("CursorMoved", { buffer = buf })
assert_eq(#deferred, scheduled_before_move + 1, "manual movement immediately reschedules auto-scroll")
assert_eq(deferred[#deferred].delay, 240, "manual movement uses the new line's reading delay")
auto_scroll.stop({ notify = false })
assert_eq(auto_scroll.is_active(buf), false, "auto-scroll stops")
assert_eq(auto_scroll.is_paused(buf), false, "stopping discards the paused session")

local folder_buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_set_current_buf(folder_buf)
vim.bo[folder_buf].buftype = "nofile"
vim.bo[folder_buf].filetype = "markdown"
vim.b[folder_buf].upsc_folder_reader_root = "/notes/focused"
vim.api.nvim_buf_set_lines(folder_buf, 0, -1, false, { "one two", "three four" })
auto_scroll.start({ notify = false })
assert_eq(auto_scroll.is_active(folder_buf), true, "auto-scroll starts in a combined folder view")
auto_scroll.stop({ notify = false })

vim.defer_fn = original_defer_fn

vim.api.nvim_buf_delete(buf, { force = true })
vim.api.nvim_buf_delete(folder_buf, { force = true })
