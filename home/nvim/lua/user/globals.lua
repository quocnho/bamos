-- Global settings (port từ lua/globals.lua của jdhao — rút gọn cho Linux/NixOS).
local utils = require("user.utils")

-- ====================== Biến môi trường ======================
vim.g.is_win = utils.has("win32") or utils.has("win64")
vim.g.is_linux = utils.has("unix") and (not utils.has("macunix"))
vim.g.is_mac = utils.has("macunix")

-- ====================== Tắt provider không dùng ======================
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0

-- ====================== Leader (theo chuẩn jdhao: dấu phẩy) ======================
-- Lưu ý: phím tắt LSP/find dùng <space> (như jdhao).
vim.g.mapleader = ","
vim.g.maplocalleader = ","

-- Highlight lua heredoc trong vim script
vim.g.vimsyn_embed = "l"

-- ====================== Tắt builtin không cần ======================
-- netrw thay bằng nvim-tree (xem plugins/explorer.lua)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.netrw_liststyle = 3

vim.g.loaded_2html_plugin = 1
vim.g.loaded_zipPlugin = 1
vim.g.loaded_gzip = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_tutor_mode_plugin = 1
vim.g.loaded_matchit = 1
vim.g.loaded_matchparen = 1 -- dùng vim-matchup
vim.g.loaded_sql_completion = 1

-- Mức log mặc định
vim.g.logging_level = vim.log.levels.INFO
