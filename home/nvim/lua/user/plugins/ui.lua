-- UI helpers: icons, notify, snacks, colorizer, render-markdown, colorful-menu,
-- dropbar, quicker/bqf (quickfix), fidget (LSP progress), lightbulb, whitespace,
-- oscyank.
local map = vim.keymap.set

-- ===== Mini.icons: icon file + mock nvim-web-devicons =====
require("mini.icons").setup()
pcall(function()
  require("mini.icons").mock_nvim_web_devicons()
  require("mini.icons").tweak_lsp_kind()
end)

-- ===== Nvim-notify: thông báo đẹp =====
require("notify").setup {
  background_colour = "#000000",
  timeout = 3000,
}
vim.notify = require("notify") -- thay thế vim.notify toàn cục

-- ===== Snacks: bộ tiện ích (indent, bigfile, notifier... bật mặc định) =====
local snacks_ok, snacks = pcall(require, "snacks")
if snacks_ok then
  snacks.setup {
    bigfile = { enabled = true },
    indent = { enabled = true, char = "│" },
    notifier = { enabled = true },
    quickfile = { enabled = true },
    scratch = { enabled = true },
    statuscolumn = { enabled = false }, -- đã dùng statuscol.nvim
    words = { enabled = true },
  }
end

-- ===== Nvim-colorizer: hiện màu hex/rgb ngay trong code =====
require("colorizer").setup {}

-- ===== Render-markdown: render markdown đẹp trong buffer =====
local render_ok, render_md = pcall(require, "render-markdown")
if render_ok then
  render_md.setup {
    heading = { enabled = true, sign = true },
    code = { enabled = true, sign = true },
    checkbox = { enabled = true },
  }
end

-- ===== Colorful-menu: menu completion màu theo kind =====
local colorful_ok, colorful_menu = pcall(require, "colorful-menu")
if colorful_ok then
  colorful_menu.setup {
    ls = {
      show_label = true,
    },
    exclude_kinds = { "File" },
  }
end

-- ===== Dropbar: breadcrumb (đường dẫn theo cú pháp) =====
local dropbar_ok, dropbar = pcall(require, "dropbar.api")
if dropbar_ok then
  map("n", "<space>b", function()
    dropbar.pick()
  end, { desc = "breadcrumb (dropbar)" })
end

-- ===== Quickfix: quicker + bqf =====
local quicker_ok, quicker = pcall(require, "quicker")
if quicker_ok then
  quicker.setup {}
end
require("bqf").setup {}

-- ===== Fidget: hiện tiến trình LSP =====
require("fidget").setup {}

-- ===== Lightbulb: gợi ý code action bên lề =====
require("nvim-lightbulb").setup {
  sign = { enabled = true, text = "💡" },
  update_time = 200,
}

-- ===== Whitespace: hiện khoảng trắng thừa =====
local ws_ok, whitespace = pcall(require, "whitespace-nvim")
if ws_ok then
  whitespace.setup {
    highlight = "DiffDelete",
  }
end

-- ===== Vim-oscyank: copy ra ngoài qua OSC52 (tmux/ssh) =====
if vim.g.is_linux then
  map({ "n", "x" }, "<leader>yo", "<cmd>OSCYank<CR>", { desc = "OSC52 yank" })
end
