local M = {}

local function picker_defaults()
  return {
    matcher = {
      fuzzy = true,
      smartcase = true,
      ignorecase = true,
      sort_empty = false,
      filename_bonus = true,
      file_pos = true,
      cwd_bonus = true,
      frecency = false,
      history_bonus = false,
    },
    sort = {
      fields = { "score:desc", "#text", "idx" },
    },
    debug = {},
  }
end

local function default_config()
  return {
    leader = " ",
    localleader = " ",
    min_nvim = "nvim-0.12",
    min_nvim_label = "0.12+",
    vault = {
      name = "upsc",
      root = vim.env.UPSC_NOTES_VAULT or "/home/bhickta/development/upsc",
      zettel_dir = "zettelkasten",
      in_dir = "in",
    },
    picker = picker_defaults(),
    markdown = {
      wrap = true,
      linebreak = true,
      breakindent = true,
      breakindentopt = "shift:2,min:40,sbr",
      showbreak = "  ",
      conceallevel = 2,
      concealcursor = "nc",
      textwidth = 0,
      spell = false,
      colorcolumn = "",
      cursorline = true,
      foldenable = false,
    },
    reading = {
      enabled_conceallevel = 2,
      disabled_conceallevel = 1,
      enabled_concealcursor = "nc",
      disabled_concealcursor = "",
      default_speed = "xfast",
      speeds = {
        slow = 150,
        medium = 250,
        fast = 350,
        xfast = 500,
      },
    },
    translation = {
      enabled = true,
      delay_ms = 500,
      executable = "curl",
      source_lang = "auto",
      target_lang = "hi",
    },
  }
end

local function is_absolute(path)
  return path:match("^/") or path:match("^%a:[/\\]") ~= nil
end

local function normalize_path(path)
  path = vim.fn.expand(path)
  if vim.fs and vim.fs.normalize then
    return vim.fs.normalize(path)
  end
  return path
end

local function joinpath(...)
  if vim.fs and vim.fs.joinpath then
    return vim.fs.joinpath(...)
  end
  return table.concat({ ... }, "/"):gsub("//+", "/")
end

function M.defaults()
  return default_config()
end

function M.validate(cfg)
  vim.validate({
    leader = { cfg.leader, "string" },
    localleader = { cfg.localleader, "string" },
    min_nvim = { cfg.min_nvim, "string" },
    vault = { cfg.vault, "table" },
    picker = { cfg.picker, "table" },
    markdown = { cfg.markdown, "table" },
    reading = { cfg.reading, "table" },
    translation = { cfg.translation, "table" },
  })

  vim.validate({
    ["vault.name"] = { cfg.vault.name, "string" },
    ["vault.root"] = { cfg.vault.root, "string" },
    ["vault.zettel_dir"] = { cfg.vault.zettel_dir, "string" },
    ["vault.in_dir"] = { cfg.vault.in_dir, "string" },
    ["reading.default_speed"] = { cfg.reading.default_speed, "string" },
    ["reading.speeds"] = { cfg.reading.speeds, "table" },
    ["translation.enabled"] = { cfg.translation.enabled, "boolean" },
    ["translation.delay_ms"] = { cfg.translation.delay_ms, "number" },
    ["translation.executable"] = { cfg.translation.executable, "string" },
    ["translation.source_lang"] = { cfg.translation.source_lang, "string" },
    ["translation.target_lang"] = { cfg.translation.target_lang, "string" },
  })

  if cfg.translation.delay_ms < 0 then
    error("upsc_notes.config: translation.delay_ms must not be negative")
  end

  if cfg.translation.executable == "" or cfg.translation.source_lang == "" or cfg.translation.target_lang == "" then
    error("upsc_notes.config: translation executable and languages must not be empty")
  end

  if type(cfg.reading.speeds[cfg.reading.default_speed]) ~= "number" then
    error("upsc_notes.config: reading.default_speed must name a configured reading speed")
  end

  for _, mode in ipairs({ "slow", "medium", "fast", "xfast" }) do
    local words_per_minute = cfg.reading.speeds[mode]
    if type(words_per_minute) ~= "number" or words_per_minute <= 0 then
      error(("upsc_notes.config: reading.speeds.%s must be a positive number"):format(mode))
    end
  end

  if cfg.vault.root == "" then
    error("upsc_notes.config: vault.root must not be empty")
  end

  local root = normalize_path(cfg.vault.root)
  if not is_absolute(root) then
    error("upsc_notes.config: vault.root must resolve to an absolute path")
  end

  if cfg.vault.zettel_dir == "" or cfg.vault.in_dir == "" then
    error("upsc_notes.config: vault subdirectories must not be empty")
  end

  cfg.vault.root = root
  cfg.paths = {
    vault_root = root,
    zettel_root = joinpath(root, cfg.vault.zettel_dir),
    in_root = joinpath(root, cfg.vault.in_dir),
  }

  return cfg
end

function M.setup(opts)
  local cfg = vim.tbl_deep_extend("force", default_config(), opts or {})
  M._config = M.validate(cfg)
  return M._config
end

function M.get()
  if not M._config then
    return M.setup()
  end
  return M._config
end

function M.picker_defaults(opts)
  return vim.tbl_deep_extend("force", M.get().picker, opts or {})
end

function M.apply_markdown_buffer_options(opts)
  opts = vim.tbl_deep_extend("force", M.get().markdown, opts or {})
  vim.opt_local.wrap = opts.wrap
  vim.opt_local.linebreak = opts.linebreak
  vim.opt_local.breakindent = opts.breakindent
  vim.opt_local.breakindentopt = opts.breakindentopt
  vim.opt_local.showbreak = opts.showbreak
  vim.opt_local.conceallevel = opts.conceallevel
  vim.opt_local.concealcursor = opts.concealcursor
  vim.opt_local.textwidth = opts.textwidth
  vim.opt_local.spell = opts.spell
  vim.opt_local.colorcolumn = opts.colorcolumn
  vim.opt_local.cursorline = opts.cursorline
  vim.opt_local.foldenable = opts.foldenable
end

function M.apply_markdown_reading_options(enabled)
  local cfg = M.get()
  local markdown = cfg.markdown
  local reading = cfg.reading

  vim.opt_local.wrap = markdown.wrap
  vim.opt_local.linebreak = markdown.linebreak
  vim.opt_local.breakindent = markdown.breakindent
  vim.opt_local.breakindentopt = markdown.breakindentopt
  vim.opt_local.showbreak = markdown.showbreak
  vim.opt_local.conceallevel = enabled and reading.enabled_conceallevel or reading.disabled_conceallevel
  vim.opt_local.concealcursor = enabled and reading.enabled_concealcursor or reading.disabled_concealcursor
  vim.opt_local.colorcolumn = markdown.colorcolumn
end

return M
