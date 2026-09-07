-- BamOS Neovim — entry point (kiến trúc hiện đại, tham khảo ray-x/nvim + LazyVim).
--
-- Nguyên tắc (phù hợp NixOS + home-manager):
--   • Plugins cài qua Nix (vimPlugins, pack native của home-manager) → KHÔNG cần
--     lazy.nvim/packer: reproducible, offline, "cài mới là chạy".
--   • Nhẹ: danh sách plugin tinh gọn, setup chỉ gọi khi thực sự dùng; mọi thứ
--     khác tận dụng native Neovim 0.12 (vim.lsp.enable, pack, treesitter…).
--   • LSP server cài qua Nix (extraPackages) HOẶC devenv shell (tự có trong PATH
--     khi `direnv allow`) → server nào có executable thì tự bật.
--   • Look LazyVim-style: snacks.dashboard (home screen) + bufferline (tab)
--     + which-key (menu phím) — xem lua/bamos/plugins/snacks.lua.
--
-- Thứ tự nạp: core (globals → options → keymaps → autocmds) → icons (trước mọi
-- plugin cần icon) → plugins theo nhóm → diagnostic → LSP → theme.
vim.loader.enable()

require("bamos.globals")
require("bamos.options")
require("bamos.keymaps")
require("bamos.autocmds")
-- Fcitx5/Unikey: tự tắt bộ gõ khi ra khỏi insert / vào command-line
-- (chỉ chạy khi có fcitx5-remote — xem đầu file ime.lua)
require("bamos.ime")

-- Icon file (mini.icons) phải nạp TRƯỚC bufferline/lualine/snacks… vì chúng
-- require("nvim-web-devicons") lúc load (mini.icons mock sẵn module này).
require("bamos.plugins.icons")

for _, mod in ipairs({
  "which-key",
  "bufferline",
  "lualine",
  "snacks",
  "cmp",
  "treesitter",
  "picker",
  "explorer",
  "git",
  "editor",
  "folding",
  "statuscol",
  "navigation",
  "markdown",
  "terminal",
  "notes",
  "todo",
  "extras",
}) do
  require("bamos.plugins." .. mod)
end

require("bamos.diagnostic")
require("bamos.lsp")

-- Colorscheme — để cuối cùng (tô highlight theo theme cho mọi plugin đã setup).
require("bamos.theme")
