-- Python (port after/ftplugin/python.lua của jdhao)
local utils = require("bamos.utils")
local opt = vim.opt

opt.wrap = false
opt.sidescroll = 5
opt.sidescrolloff = 2
opt.colorcolumn = "100"

-- Python chuẩn PEP8: 4 spaces
opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.expandtab = true

local py_env = utils.get_py_env()

-- Chạy file Python: <F9> (dùng AsyncRun nếu có, không thì :!python)
local py_cmd = "python"
if py_env == "uv" then
  py_cmd = "uv run python" -- devenv/uv project → chạy đúng env
end
vim.keymap.set("n", "<F9>", string.format(":<C-U>!%s -u %%<CR>", py_cmd), {
  buffer = true,
  silent = true,
  desc = "run python",
})

-- Format: black (như jdhao); project uv → uv run black
local py_fmt_cmd = "!black"
if py_env == "uv" then
  py_fmt_cmd = "!uv run black"
end
vim.keymap.set("n", "<space>f", string.format("<cmd>silent %s %%<CR>", py_fmt_cmd), {
  buffer = true,
  silent = true,
  desc = "format with black",
})
