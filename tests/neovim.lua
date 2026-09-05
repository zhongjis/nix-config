-- Run with the built NVF: nvim --headless '+lua dofile("tests/neovim.lua")'
-- Use temporary XDG_DATA_HOME, XDG_STATE_HOME and XDG_CACHE_HOME.
local root = vim.fn.tempname()
vim.fn.mkdir(root, "p")
vim.opt.undodir = root .. "/undo"
local function eq(actual, expected, message)
  assert(vim.deep_equal(actual, expected), message .. ": " .. vim.inspect(actual))
end
local function lines() return vim.api.nvim_buf_get_lines(0, 0, -1, false) end
local function set(text) vim.api.nvim_buf_set_lines(0, 0, -1, false, { text }) end
local function key(lhs)
  local mapping = vim.fn.maparg(vim.g.mapleader .. lhs, "n", false, true)
  assert(mapping.callback or mapping.rhs, "missing mapping: " .. lhs)
  if mapping.callback then
    mapping.callback()
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(mapping.rhs, true, false, true), "nx", false)
  end
end
local function run()
  -- Real Conform + shfmt, no formatter mocks and no project LSP required.
  local file = root .. "/save.sh"
  vim.fn.writefile({ "echo 1" }, file)
  vim.cmd.edit(file)
  require("conform") -- Force lazy loading before synchronous headless write events.
  set("echo    2")
  vim.cmd.enew()
  eq(vim.fn.readfile(file), { "echo 1" }, "BufLeave must not save")
  vim.cmd.buffer(vim.fn.bufnr(file))
  vim.api.nvim_exec_autocmds("FocusLost", {})
  eq(vim.fn.readfile(file), { "echo 1" }, "FocusLost must not save")
  vim.cmd("FormatDisable")
  vim.cmd.write()
  eq(vim.fn.readfile(file), { "echo    2" }, "disabled explicit save is unformatted")
  vim.cmd("FormatEnable")
  vim.cmd.write()
  eq(vim.fn.readfile(file), { "echo 2" }, "enabled explicit save formats synchronously")
  vim.cmd("FormatDisable!")
  set("echo    3")
  vim.cmd.write()
  eq(vim.fn.readfile(file), { "echo    3" }, "buffer disable respected")
  vim.cmd("FormatEnable!")
  vim.cmd.write()
  eq(vim.fn.readfile(file), { "echo 3" }, "buffer enable respected")
  key("tf")
  eq(vim.g.formatsave, false, "toggle uses native global flag")
  key("tf")
  default_on_attach({}, vim.api.nvim_get_current_buf())
  key("ltf")
  eq(vim.b.disableFormatSave, true, "native buffer toggle works")
  key("ltf")
  set("echo    4")
  vim.cmd("Format")
  assert(vim.wait(5000, function() return lines()[1] == "echo 4" end), "Format uses shfmt")
  set("echo    5")
  key("lf")
  assert(vim.wait(5000, function() return lines()[1] == "echo 5" end), "lf uses shfmt")
  eq(vim.fn.readfile(file), { "echo 3" }, "manual format does not save")

  local ts = vim.lsp.config["typescript-language-server"]
  for _, ft in ipairs({ "typescript", "javascript", "typescriptreact", "javascriptreact" }) do
    assert(vim.tbl_contains(ts.filetypes, ft), "TypeScript server missing " .. ft)
  end
  local preferences = ts.init_options.preferences
  eq(preferences.includeCompletionsForModuleExports, true, "module auto imports")
  eq(preferences.includeCompletionsForImportStatements, true, "import completions")
  eq(preferences.includePackageJsonAutoImports, "auto", "package auto imports")
  eq(preferences.includeInlayParameterNameHints, "all", "parameter hints")
  eq(preferences.includeInlayParameterNameHintsWhenArgumentMatchesName, false, "suppress redundant hints")
  for _, name in ipairs({ "FunctionParameterType", "VariableType", "PropertyDeclarationType", "FunctionLikeReturnType", "EnumMemberValue" }) do
    eq(preferences["includeInlay" .. name .. "Hints"], true, name .. " hints")
  end
  local python = vim.lsp.config.basedpyright.settings.basedpyright
  eq(python.analysis.typeCheckingMode, "standard", "standard Python checking")
  eq(python.analysis.autoImportCompletions, true, "Python auto imports")
  eq(python.disableOrganizeImports, true, "Ruff owns imports")
  assert(vim.lsp.is_enabled("basedpyright") and vim.lsp.is_enabled("ruff"), "Python servers enabled")
  assert(not vim.lsp.is_enabled("pyright"), "no competing Pyright")
  local client = { server_capabilities = { hoverProvider = true } }
  vim.lsp.config.ruff.on_attach(client, 0)
  eq(client.server_capabilities.hoverProvider, false, "Basedpyright owns hover")
  vim.fn.writefile({ "[tool.black]", "line-length = 120" }, root .. "/pyproject.toml")
  vim.cmd.edit(root .. "/format.py")
  local long = 'values = ["aaaaaaaaaaaaaaaaaaaa", "bbbbbbbbbbbbbbbbbbbb", "cccccccccccccccccccc", "dddddddddddddddddddd"]'
  set(long)
  require("conform").format({ async = false, timeout_ms = 5000 })
  eq(lines(), { long }, "Black respects project line length")

  eq(vim.o.swapfile, true, "swap recovery enabled")
  eq(vim.o.undofile, true, "persistent undo enabled")
  require("blink.cmp")
  eq(require("blink.cmp.config").completion.list.selection.auto_insert(), false, "completion does not insert before acceptance")
  local lint = require("lint")
  eq(lint.linters_by_ft.python or {}, {}, "Python diagnostics only via LSP")
  eq(lint.linters_by_ft.markdown, { "markdownlint-cli2" }, "one Markdown provider")
  assert(vim.tbl_contains(lint.linters_by_ft.nix, "statix"), "Nix tooling preserved")
  for _, ft in ipairs({ "javascript", "typescript", "javascriptreact", "typescriptreact" }) do
    eq(lint.linters_by_ft[ft] or {}, {}, "no competing generic web lint: " .. ft)
  end
  -- Keep the real nvim-lint process interface; substitute only the external CLI
  -- with pwd to observe its cwd without requiring project ESLint dependencies.
  local original = lint.linters.eslint_d
  local calls = {}
  lint.linters.eslint_d = {
    cmd = "pwd", stdin = false, append_fname = false,
    parser = function(output, bufnr)
      calls[#calls + 1] = { vim.trim(output), bufnr }
      return {}
    end,
  }
  local nested = root .. "/web/nested"
  vim.fn.mkdir(nested .. "/src", "p")
  vim.fn.writefile({ "" }, root .. "/web/eslint.config.js")
  vim.fn.writefile({ "" }, nested .. "/eslint.config.cts")
  local cwd = vim.fn.getcwd()
  for _, ext in ipairs({ "js", "ts", "jsx", "tsx" }) do
    local web = nested .. "/src/test." .. ext
    vim.fn.writefile({ "const value = 1;" }, web)
    vim.cmd.edit(web)
    local buf = vim.api.nvim_get_current_buf()
    local count = #calls
    assert(vim.wait(3000, function() return #calls > count end), "lint on read: " .. ext)
    eq(calls[#calls], { nested, buf }, "nearest config cwd and event buffer")
    count = #calls
    vim.api.nvim_exec_autocmds("BufWritePost", { buffer = buf })
    assert(vim.wait(3000, function() return #calls > count end), "lint on write")
    eq(#calls, count + 1, "one lint invocation per event")
  end
  local count = #calls
  vim.fn.writefile({ "const value = 1;" }, root .. "/no-config.js")
  vim.cmd.edit(root .. "/no-config.js")
  vim.api.nvim_exec_autocmds("BufWritePost", { buffer = 0 })
  vim.wait(200)
  eq(#calls, count, "no explicit config means no ESLint")
  eq(vim.fn.getcwd(), cwd, "lint never changes global cwd")
  lint.linters.eslint_d = original
end
local ok, err = xpcall(run, debug.traceback)
vim.cmd("silent! %bwipeout!")
vim.fn.delete(root, "rf")
if not ok then
  io.stderr:write(err .. "\n")
  vim.cmd("cquit 1")
else
  print("NVF regression: PASS")
  vim.cmd("qa!")
end
