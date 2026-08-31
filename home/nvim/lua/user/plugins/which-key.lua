-- Which-key — gợi ý phím tắt khi gõ leader/, <space> (port của jdhao).
local wk = require("which-key")

wk.setup {
  plugins = {
    spelling = { enabled = true },
  },
  icons = {
    breadcrumb = "»",
    separator = "➜",
    group = "+",
  },
  win = {
    border = "rounded",
    padding = { 1, 2, 1, 2 },
  },
}

wk.add {
  { "<leader>w", desc = "lưu buffer" },
  { "<leader>q", desc = "thoát" },
  { "<leader>p", desc = "dán (paste)" },
  { "<leader>v", desc = "chọn lại vùng dán" },
  { "<leader>y", desc = "yank toàn buffer" },
  { "<leader>cd", desc = "đổi cwd" },
  { "<leader>cb", desc = "blink con trỏ" },
  { "<leader>cl", desc = "toggle cột" },
  { "<leader>sv", desc = "restart nvim" },
  { "<leader><space>", desc = "xoá trailing space" },
  { "<leader>a", desc = "swap tham số (next)" },
  { "<leader>A", desc = "swap tham số (prev)" },
  { "<space>f", group = "fzf-lua (tìm kiếm)" },
  { "<space>g", group = "git" },
  { "<space>d", group = "diagnostics" },
  { "<space>r", group = "refactor" },
  { "<space>w", group = "workspace" },
  { "<space>s", desc = "file explorer (nvim-tree)" },
  { "<space>t", desc = "toggle terminal" },
  { "<space>z", desc = "fold (ufo)" },
}
