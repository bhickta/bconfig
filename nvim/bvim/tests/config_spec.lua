package.path = vim.fn.getcwd() .. "/lua/?.lua;" .. vim.fn.getcwd() .. "/lua/?/init.lua;" .. package.path

local config = require("upsc_notes.config")
local original_env = vim.env.UPSC_NOTES_VAULT
local default_vault = vim.fn.expand("~/development/upsc")

local function reset()
  config._config = nil
  vim.env.UPSC_NOTES_VAULT = original_env
end

local function assert_eq(actual, expected, message)
  if actual ~= expected then
    error(("%s\nexpected: %s\nactual: %s"):format(message or "assertion failed", vim.inspect(expected), vim.inspect(actual)), 2)
  end
end

local function test_defaults()
  reset()
  local cfg = config.setup()
  assert_eq(cfg.leader, " ", "default leader")
  assert_eq(cfg.vault.name, "upsc", "default vault name")
  assert_eq(cfg.paths.vault_root, default_vault, "default vault root")
  assert_eq(cfg.paths.zettel_root, default_vault .. "/zettelkasten", "default zettel path")
  assert_eq(cfg.paths.in_root, default_vault .. "/in", "default in path")
  assert_eq(cfg.reading.default_speed, "slow", "default reading speed")
  assert_eq(cfg.markdown.render, true, "Markdown rendering enabled by default")
  assert_eq(cfg.markdown.block_focus, true, "block focus enabled by default")
  assert_eq(cfg.reading.speeds.xxslow, 60, "xxslow words per minute")
  assert_eq(cfg.reading.speeds.xslow, 100, "xslow words per minute")
  assert_eq(cfg.reading.speeds.xfast, 500, "xfast words per minute")
  assert_eq(cfg.translation.enabled, true, "visual translation enabled")
  assert_eq(cfg.translation.target_lang, "hi", "Hindi translation target")
end

local function test_user_overrides()
  reset()
  local cfg = config.setup({
    leader = ",",
    vault = {
      root = "/tmp/upsc-test-vault",
      zettel_dir = "zk",
      in_dir = "inbox",
    },
  })

  assert_eq(cfg.leader, ",", "leader override")
  assert_eq(cfg.paths.vault_root, "/tmp/upsc-test-vault", "vault root override")
  assert_eq(cfg.paths.zettel_root, "/tmp/upsc-test-vault/zk", "zettel dir override")
  assert_eq(cfg.paths.in_root, "/tmp/upsc-test-vault/inbox", "in dir override")
end

local function test_env_fallback()
  reset()
  vim.env.UPSC_NOTES_VAULT = "/tmp/upsc-env-vault"
  local cfg = config.setup()
  assert_eq(cfg.paths.vault_root, "/tmp/upsc-env-vault", "env vault root")
end

local function test_validation()
  reset()
  local ok, err = pcall(function()
    config.setup({
      vault = {
        root = "relative/path",
      },
    })
  end)

  if ok then
    error("relative vault root should fail validation")
  end

  if not tostring(err):find("absolute path", 1, true) then
    error("validation error should mention absolute path: " .. tostring(err))
  end
end

test_defaults()
test_user_overrides()
test_env_fallback()
test_validation()
reset()
