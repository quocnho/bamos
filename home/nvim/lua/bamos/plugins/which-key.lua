-- Which-key v3 — popup gợi ý phím tắt (look LazyVim: cửa sổ bo góc, icon).
--
-- which-key v3 TỰ nhận diện mọi keymap có `desc` → không cần khai báo từng
-- phím; chỉ cần nhóm (group) + ghi chú vài phím leader đặc biệt.
local wk = require("which-key")

wk.setup {
  -- Hiện phím bấm thực tế (jkhl…) thay vì chỉ chuỗi
  show_keys = true,
  -- Tự bật theo marks/spelling + presets phổ biến
  plugins = {
    spelling = true,
    presets = {
      operators = true,
      motions = true,
      text_objects = true,
      windows = true,
      nav = true,
      z = true,
      g = true,
    },
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

-- Nhóm cho prefix <space> (mọi keymap <space>… trong config đều có desc nên
-- which-key tự gom — các dòng dưới chỉ đặt tên group + ghi chú leader ",")
wk.add {
  { "<space>f", group = "tìm kiếm (fzf-lua)" },
  { "<space>g", group = "git" },
  { "<space>d", group = "diagnostics" },
  { "<space>r", group = "refactor (LSP)" },
  { "<space>w", group = "workspace (LSP)" },
  { "<space>z", group = "fold (ufo)" },
  { "<space>s", desc = "file explorer (nvim-tree)" },
  { "<space>o", desc = "outline (aerial)" },
  { "<space>b", desc = "buffers (fzf-lua)" },
  { "<space>u", group = "ui (theme…)" },
  { "<leader>w", desc = "lưu buffer" },
  { "<leader>q", desc = "thoát" },
  { "<leader>p", desc = "dán (paste)" },
  { "<leader>v", desc = "chọn lại vùng dán" },
  { "<leader>y", desc = "yank toàn buffer" },
  { "<leader>cd", desc = "đổi cwd" },
  { "<leader>cl", desc = "toggle cột" },
  { "<leader><space>", desc = "xoá trailing space" },
  { "<leader>ut", desc = "theme tiếp theo" },
  { "<leader>uT", desc = "theme trước" },
}
