return {
  size = 12,
  direction = "float",
  shade_terminals = false,
  float_opts = {
    border = "rounded",
    width = function()
      return math.min(120, math.floor(vim.o.columns * 0.8))
    end,
    height = function()
      return math.min(32, math.floor(vim.o.lines * 0.75))
    end,
  },
  highlights = {
    Normal = { link = "Normal" },
    NormalFloat = { link = "NormalFloat" },
    FloatBorder = { link = "FloatBorder" },
    StatusLine = { link = "StatusLine" },
    StatusLineNC = { link = "StatusLineNC" },
    WinBar = { link = "WinBar" },
    WinBarNC = { link = "WinBarNC" },
  },
  on_create = function(term)
    vim.opt_local.foldcolumn = "0"
    vim.opt_local.signcolumn = "no"
    vim.opt_local.winbar = ""
    local function toggle()
      term:toggle()
    end
    vim.keymap.set({ "n", "t", "i" }, "<F7>", toggle, {
      buffer = term.bufnr,
      desc = "Toggle terminal",
    })
    vim.keymap.set({ "n", "t", "i" }, "<C-'>", toggle, {
      buffer = term.bufnr,
      desc = "Toggle terminal",
    })
  end,
}
