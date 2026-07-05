local icons = require("upsc_notes.astroui.icons")

return {
  enabled = true,
  preset = "obsidian",
  render_modes = { "n", "c", "t" },
  max_file_size = 8.0,
  debounce = 80,
  file_types = { "markdown" },
  completions = {
    lsp = {
      enabled = false,
    },
  },
  heading = {
    enabled = true,
    sign = false,
    width = "full",
    right_pad = 1,
    icons = icons.markdown.headings,
    backgrounds = {
      "RenderMarkdownH1Bg",
      "RenderMarkdownH2Bg",
      "RenderMarkdownH3Bg",
      "RenderMarkdownH4Bg",
      "RenderMarkdownH5Bg",
      "RenderMarkdownH6Bg",
    },
    foregrounds = {
      "RenderMarkdownH1",
      "RenderMarkdownH2",
      "RenderMarkdownH3",
      "RenderMarkdownH4",
      "RenderMarkdownH5",
      "RenderMarkdownH6",
    },
  },
  code = {
    enabled = true,
    sign = false,
    style = "full",
    position = "left",
    language_pad = 1,
    left_pad = 1,
    right_pad = 1,
    min_width = 60,
    border = "thin",
  },
  bullet = {
    enabled = true,
    icons = { "•", "◦", "▪", "▫" },
  },
  checkbox = {
    enabled = true,
    unchecked = {
      icon = icons.markdown.unchecked,
    },
    checked = {
      icon = icons.markdown.checked,
    },
  },
  quote = {
    enabled = true,
    icon = "▌",
  },
  pipe_table = {
    enabled = true,
    preset = "round",
  },
  callout = {
    note = { raw = "[!NOTE]", rendered = icons.markdown.note .. " Note", highlight = "RenderMarkdownInfo" },
    tip = { raw = "[!TIP]", rendered = icons.markdown.tip .. " Tip", highlight = "RenderMarkdownSuccess" },
    important = { raw = "[!IMPORTANT]", rendered = icons.markdown.important .. " Important", highlight = "RenderMarkdownHint" },
    warning = { raw = "[!WARNING]", rendered = icons.markdown.warning .. " Warning", highlight = "RenderMarkdownWarn" },
    caution = { raw = "[!CAUTION]", rendered = icons.markdown.caution .. " Caution", highlight = "RenderMarkdownError" },
  },
  link = {
    enabled = true,
    image = icons.markdown.image,
    email = icons.markdown.email,
    hyperlink = icons.markdown.hyperlink,
    wiki = {
      icon = icons.markdown.wiki,
    },
  },
  win_options = {
    conceallevel = {
      default = 2,
      rendered = 3,
    },
    concealcursor = {
      default = "nc",
      rendered = "",
    },
  },
}
