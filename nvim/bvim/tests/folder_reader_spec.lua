package.path = vim.fn.getcwd() .. "/lua/?.lua;" .. vim.fn.getcwd() .. "/lua/?/init.lua;" .. package.path

require("upsc_notes.config").setup()
local reader = require("upsc_notes.folder_reader")

local function assert_eq(actual, expected, message)
  if not vim.deep_equal(actual, expected) then
    error(("%s\nexpected: %s\nactual: %s"):format(message, vim.inspect(expected), vim.inspect(actual)), 2)
  end
end

local root = vim.fn.tempname()
vim.fn.mkdir(root .. "/nested/deeper", "p")
vim.fn.mkdir(root .. "/.git", "p")
vim.fn.writefile({ "# Alpha", "one two" }, root .. "/01-alpha.md")
vim.fn.writefile({ "# Beta", "three four five" }, root .. "/02-beta.MD")
vim.fn.writefile({ "# Nested", "must also appear" }, root .. "/nested/03-nested.md")
vim.fn.writefile({ "# Deep", "six" }, root .. "/nested/deeper/04-deep.md")
vim.fn.writefile({ "ignored" }, root .. "/notes.txt")
vim.fn.writefile({ "hidden" }, root .. "/.git/hidden.md")

assert_eq(
  reader.nest_headings({ "# One", "## Two", "###### Six", "```markdown", "# code", "```" }, 2),
  { "### One", "#### Two", "###### Six", "```markdown", "# code", "```" },
  "source headings should nest below folder and file headings without changing fenced code"
)

assert_eq(
  vim.tbl_map(function(path) return path:sub(#root + 2) end, reader.markdown_files(root)),
  { "01-alpha.md", "02-beta.MD", "nested/03-nested.md", "nested/deeper/04-deep.md" },
  "folder reader should recursively collect Markdown files and skip metadata directories"
)

local document = reader.compose(root)
assert_eq(document.file_count, 4, "combined document file count")
assert_eq(document.words, 17, "combined document word count")
assert_eq(#document.sections, 4, "combined document sections")
assert_eq(document.sections[1].relative_path, "01-alpha.md", "first section label")
assert_eq(document.sections[2].relative_path, "02-beta.MD", "second section label")
assert_eq(document.sections[3].relative_path, "nested/03-nested.md", "nested section label")
assert_eq(vim.tbl_contains(document.lines, "## nested"), true, "subfolders should appear in the document hierarchy")
assert_eq(vim.tbl_contains(document.lines, "### 03-nested.md"), true, "nested notes should sit below their folder")
assert_eq(vim.tbl_contains(document.lines, "## 03-nested.md"), false, "nested notes should not be flattened")
assert_eq(vim.tbl_contains(document.lines, "## nested/03-nested.md"), false, "section headings should hide relative paths")
assert_eq(vim.tbl_contains(document.lines, "#### Nested"), true, "source headings should be nested below file names")
assert_eq(vim.tbl_contains(document.lines, "### deeper"), true, "deeper folders should add another heading level")
assert_eq(vim.tbl_contains(document.lines, "#### 04-deep.md"), true, "deeper notes should sit below their folder")
assert_eq(vim.tbl_contains(document.lines, "##### Deep"), true, "deep note headings should sit below their file")
assert_eq(
  reader.section_at(document.sections, document.sections[2].content_start).path,
  vim.fs.normalize(root .. "/02-beta.MD"),
  "cursor lines should resolve to their source note"
)

local alpha_buf = vim.fn.bufadd(root .. "/01-alpha.md")
vim.fn.bufload(alpha_buf)
vim.api.nvim_buf_set_lines(alpha_buf, 0, -1, false, { "# Alpha", "unsaved content is visible" })
document = reader.compose(root)
assert_eq(
  vim.tbl_contains(document.lines, "unsaved content is visible"),
  true,
  "combined documents should include unsaved changes from loaded notes"
)

reader.open(root)
local buf = vim.api.nvim_get_current_buf()
assert_eq(vim.bo[buf].buftype, "nofile", "folder view should be a scratch buffer")
assert_eq(vim.bo[buf].modifiable, false, "folder view should be read-only")
assert_eq(vim.bo[buf].readonly, true, "folder view should reject writes")
assert_eq(vim.b[buf].upsc_folder_reader_root, vim.fs.normalize(root), "folder view should remember its root")

for lhs, description in pairs({
  ["]f"] = "Next folder note",
  ["[f"] = "Previous folder note",
  gf = "Open source note",
  R = "Refresh folder view",
}) do
  local mapping = vim.fn.maparg(lhs, "n", false, true)
  assert_eq(mapping.desc, description, "folder view mapping " .. lhs)
end

local folder_buf = buf
local nested = vim.b[buf].upsc_folder_reader_sections[3]
vim.api.nvim_win_set_cursor(0, { nested.content_start + 1, 0 })
reader.open_source()
assert_eq(
  vim.fs.normalize(vim.api.nvim_buf_get_name(0)),
  vim.fs.normalize(root .. "/nested/03-nested.md"),
  "opening a nested combined section should edit its source note"
)
assert_eq(vim.api.nvim_win_get_cursor(0)[1], 2, "source note should open at the corresponding content line")

local actual_reader = package.loaded["upsc_notes.folder_reader"]
local actual_manager = package.loaded["neo-tree.sources.manager"]
local captured_root
package.loaded["upsc_notes.folder_reader"] = {
  open = function(path)
    captured_root = path
  end,
}
package.loaded["neo-tree.sources.manager"] = {
  get_state_for_window = function()
    return { name = "filesystem", path = root }
  end,
}
package.loaded["upsc_notes.actions"] = nil
require("upsc_notes.actions").read_focused_folder()
assert_eq(captured_root, root, "global folder reading should use Neo-tree's focused root")
package.loaded["upsc_notes.actions"] = nil
package.loaded["upsc_notes.folder_reader"] = actual_reader
package.loaded["neo-tree.sources.manager"] = actual_manager

vim.cmd.bdelete({ bang = true })
if vim.api.nvim_buf_is_valid(folder_buf) then
  vim.api.nvim_buf_delete(folder_buf, { force = true })
end
if vim.api.nvim_buf_is_valid(alpha_buf) then
  vim.api.nvim_buf_delete(alpha_buf, { force = true })
end
vim.fn.delete(root, "rf")
