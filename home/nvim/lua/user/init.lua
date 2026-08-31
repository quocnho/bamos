-- BamOS Neovim — entry point (theo chuẩn jdhao/nvim-config).
--
-- Điều chỉnh cho NixOS + devenv:
--   • Plugins cài qua Nix (vimPlugins) → KHÔNG cần lazy.nvim/packer.
--   • LSP server cài qua Nix (extraPackages) HOẶC qua devenv shell (tự có trong
--     PATH khi `direnv allow`) → dùng API `vim.lsp.enable()` (Neovim ≥ 0.11),
--     server nào có executable trong PATH thì tự bật, không cần khai báo thêm.
--
-- Thứ tự nạp giống jdhao: globals → options → autocmd → mappings → plugins
-- → lsp → diagnostic → ui.
local utils = require("user.utils")

vim.loader.enable()

-- các global settings (leader, disable builtin plugins...)
require("user.globals")

-- editor options
require("user.options")

-- autocommands
require("user.autocmd")

-- keymaps
require("user.mappings")

-- cấu hình từng plugin (mỗi nhóm 1 file, như lua/config/* của jdhao)
for _, mod in ipairs({
  "fzf-lua",
  "blink-cmp",
  "treesitter",
  "lualine",
  "bufferline",
  "which-key",
  "git",
  "navigation",
  "explorer",
  "editor",
  "ui",
}) do
  require("user.plugins." .. mod)
end

-- LSP (vim.lsp.enable + PATH detection — devenv-friendly)
require("user.lsp")

-- diagnostics
require("user.diagnostic")

-- colorscheme (ngẫu nhiên từ danh sách, như jdhao)
require("user.ui")
