-- Which-key v3 — popup gợi ý phím tắt (look LazyVim: cửa sổ bo góc, icon).
--
-- which-key v3 TỰ nhận diện mọi keymap có `desc` → không cần khai báo từng
-- phím; các dòng dưới chỉ đặt tên NHÓM cho prefix có nhiều phím con.
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

-- Chỉ khai báo group cho các prefix CÓ phím con (phím đơn tự hiện desc).
-- Prefix <space>:
--   f = tìm kiếm (fzf-lua)   g = git    q = diagnostics → quickfix
--   c = code action / LSP    r = rename / workspace (LSP)
--   t = terminal             z = fold   h = hop (nhảy nhanh)
--   s/o/e/y/T = phím đơn (desc tự hiện)
wk.add {
  { "<space>f", group = "tìm kiếm (fzf-lua)" },
  { "<space>g", group = "git" },
  { "<space>q", group = "diagnostics → quickfix" },
  { "<space>c", group = "code action (LSP)" },
  { "<space>r", group = "refactor (LSP)" },
  { "<space>w", group = "workspace (LSP)" },
  { "<space>t", group = "terminal" },
  { "<space>z", group = "fold (ufo)" },
  { "<space>h", group = "hop (nhảy nhanh)" },
}

-- Prefix leader `,`: g = git hunk, u = UI/theme, còn lại phím đơn.
wk.add {
  { "<leader>g", group = "git (gitsigns hunk)" },
  { "<leader>u", group = "ui / theme" },
  { "<leader>n", desc = "ghi chú nhanh (MyNote)" },
  { "<leader>w", desc = "lưu buffer" },
  { "<leader>q", desc = "thoát (save & quit)" },
  { "<leader>p", desc = "dán (paste)" },
  { "<leader>v", desc = "chọn lại vùng dán" },
  { "<leader>y", desc = "yank toàn buffer" },
  { "<leader>cd", desc = "đổi cwd" },
  { "<leader>cl", desc = "toggle cột" },
  { "<leader><space>", desc = "xoá trailing space" },
}
