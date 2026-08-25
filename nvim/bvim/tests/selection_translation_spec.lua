package.path = vim.fn.getcwd() .. "/lua/?.lua;" .. vim.fn.getcwd() .. "/lua/?/init.lua;" .. package.path

require("upsc_notes.config").setup()
local translation = require("upsc_notes.selection_translation")

local function assert_eq(actual, expected, message)
  if not vim.deep_equal(actual, expected) then
    error(("%s\nexpected: %s\nactual: %s"):format(message, vim.inspect(expected), vim.inspect(actual)), 2)
  end
end

local lines = { "alpha beta", "gamma delta", "epsilon" }
assert_eq(translation.selection_text(lines, 1, 7, 1, 10, "v"), "beta", "character selection")
assert_eq(translation.selection_text(lines, 2, 5, 1, 7, "v"), "beta\ngamma", "backward selection")
assert_eq(translation.selection_text(lines, 1, 1, 2, 1, "V"), "alpha beta\ngamma delta", "line selection")
assert_eq(translation.selection_text(lines, 1, 1, 2, 5, "\22"), "alpha\ngamma", "block selection")
assert_eq(translation.selection_text({ "a café" }, 1, 3, 1, 6, "v"), "café", "UTF-8 selection")

local parsed = translation.parse_google_response(vim.json.encode({
  src = "en",
  sentences = {
    { trans = "नमस्ते " },
    { trans = "दुनिया" },
  },
}))
assert_eq(parsed, { text = "नमस्ते दुनिया", source_lang = "en" }, "Google response parsing")
assert_eq(translation.parse_google_response("not json"), nil, "invalid responses are rejected")

local args = translation.curl_args()
assert_eq(vim.tbl_contains(args, "q@-"), true, "selected text is sent over stdin")
assert_eq(vim.tbl_contains(args, "tl=hi"), true, "Hindi is the target language")
