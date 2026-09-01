local M = {}

local function folder_reader()
  return require("upsc_notes.folder_reader")
end

function M.items(limit)
  return vim.tbl_map(function(entry)
    local display_path = vim.fn.fnamemodify(entry.root, ":~")
    return {
      text = "Folder View " .. display_path,
      folder_root = entry.root,
      display_path = display_path,
    }
  end, folder_reader().recent(limit))
end

function M.open_item(item)
  if type(item) ~= "table" or type(item.folder_root) ~= "string" then
    return false
  end
  folder_reader().open(item.folder_root)
  return true
end

function M.picker_options(items)
  items = items or M.items()
  if #items == 0 then
    return nil
  end

  return {
    title = "Recent files and Folder Views",
    multi = {
      {
        source = "folder_views",
        finder = function()
          return items
        end,
        format = function(item)
          return {
            { "󰉋  ", "Directory" },
            { "Folder View  ", "Title" },
            { item.display_path, "Comment" },
          }
        end,
        preview = "none",
        confirm = function(picker, item)
          picker:close()
          vim.schedule(function()
            M.open_item(item)
          end)
        end,
      },
      { source = "recent" },
    },
  }
end

return M
