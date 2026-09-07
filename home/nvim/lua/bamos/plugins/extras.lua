-- Các tiện ích nhỏ: colorizer, illuminate, lightbulb, fidget, bqf, OSC52.
local map = vim.keymap.set

-- ===== Colorizer: hiện màu hex/rgb ngay trong code =====
require("colorizer").setup {}

-- ===== Vim-illuminate: highlight từ cùng tên =====
require("illuminate").configure {
  delay = 200,
  filetypes_denylist = { "aerial", "NvimTree", "qf", "snacks_dashboard" },
}

-- ===== Lightbulb: gợi ý code action bên lề =====
require("nvim-lightbulb").setup {
  sign = { enabled = true, text = "💡" },
  update_time = 200,
}

-- ===== Fidget: hiện tiến trình LSP =====
require("fidget").setup {}

-- ===== Bqf: cửa sổ quickfix đẹp (preview…) =====
require("bqf").setup {}

-- ===== Vim-oscyank: copy ra ngoài qua OSC52 (tmux/ssh) =====
if vim.g.is_linux then
  map({ "n", "x" }, "<leader>Y", "<cmd>OSCYank<CR>", { desc = "OSC52 yank" })
end
