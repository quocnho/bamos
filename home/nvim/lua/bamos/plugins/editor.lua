-- Editor helpers: autopairs, sandwich, commentary, repeat, eunuch, yanky,
-- matchup (đảm nhiệm % thông minh), targets.vim (text objects).
local map = vim.keymap.set

-- ===== Autopairs: tự đóng ngoặc =====
require("nvim-autopairs").setup {
  check_ts = true, -- hiểu ngữ cảnh treesitter
  map_c_h = true, -- <C-h> xoá cặp
}

-- ===== Vim-sandwich: bọc/xoá cặp (cs/ds/ys) — giữ phím `s` =====
map({ "n", "o" }, "s", "<Nop>", { desc = "s dành cho vim-sandwich" })

-- ===== Commentary: comment code (gc/gcc) =====
map("n", "gcc", "<Plug>CommentaryLine", { desc = "comment line" })
map("n", "gc", "<Plug>Commentary", { desc = "comment" })
map("x", "gc", "<Plug>Commentary", { desc = "comment selection" })

-- ===== vim-repeat: lặp lại plugin map bằng "." (tự hoạt động) =====

-- ===== Better-escape: gõ "jk" thoát insert (tự viết, không cần plugin) =====
map("i", "jk", "<Esc>", { desc = "thoát insert (jk)" })

-- ===== Yanky: lịch sử yank (p/P sau dán chuyển qua lại) =====
require("yanky").setup {
  highlight = { on_put = true, on_yank = true, timer = 200 },
  ring = { history_length = 100, storage = "shada" },
}
map("n", "<space>y", "<cmd>YankyRingHistory<CR>", { desc = "yank history" })
map("n", "p", "<Plug>(YankyPutAfter)", { desc = "put after (yanky)" })
map("n", "P", "<Plug>(YankyPutBefore)", { desc = "put before (yanky)" })
map("x", "p", "<Plug>(YankyPutAfter)", { desc = "put after (yanky)" })
map("x", "P", "<Plug>(YankyPutBefore)", { desc = "put before (yanky)" })
map("n", "<C-p>", "<Plug>(YankyCycleForward)", { desc = "cycle yank forward" })
map("n", "<C-n>", "<Plug>(YankyCycleBackward)", { desc = "cycle yank backward" })

-- ===== Vim-matchup: % thông minh theo cú pháp (thay matchparen) =====
-- (tự hoạt động khi cài — không cần setup)

-- ===== Targets.vim: text objects theo dấu câu/ngoặc (a"/i") =====
-- (tự hoạt động khi cài — dùng phím mặc định)
