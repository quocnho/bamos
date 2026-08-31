-- Editor helpers: autopairs, sandwich, commentary, targets, repeat,
-- better-escape (viết tay), iswap, yanky, statuscol, indentscope, illuminate.
local map = vim.keymap.set

-- ===== Autopairs: tự đóng ngoặc =====
require("nvim-autopairs").setup {
  check_ts = true, -- hiểu ngữ cảnh treesitter
  map_c_h = true, -- <C-h> xoá cặp
}

-- ===== Vim-sandwich: thêm/bọc/xoá cặp bao quanh (cs/ds/ys) =====
-- giữ phím `s` cho sandwich (jdhao map s → nop, dùng cl thay s)
map({ "n", "o" }, "s", "<Nop>", { desc = "s dành cho vim-sandwich" })

-- ===== Commentary: comment code (gc/gcc) =====
map("n", "gcc", "<Plug>CommentaryLine", { desc = "comment line" })
map("n", "gc", "<Plug>Commentary", { desc = "comment" })
map("x", "gc", "<Plug>Commentary", { desc = "comment selection" })

-- ===== Targets: text objects nâng cao (dùng phím mặc định) =====

-- ===== Repeat: vim-repeat (tự hoạt động qua plug map) =====

-- ===== Better-escape: gõ "jk" thoát insert (thay better-escape.vim) =====
map("i", "jk", "<Esc>", { desc = "thoát insert (jk)" })

-- ===== IsWap: đổi chỗ 2 tham số/điều kiện (gS) =====
require("iswap").setup {
  keys = { "f", "d", "s", "a", "w", "e", "r" },
}
map("n", "gS", "<cmd>ISwap<CR>", { desc = "iswap" })
map("x", "gS", "<cmd>ISwapWith<CR>", { desc = "iswap with" })

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

-- ===== Statuscol: cột số/sign gọn gàng =====
require("statuscol").setup {
  segments = {
    { text = { "%s" }, click = "v:lua.ScFa" },
    { text = { "%C" }, click = "v:lua.ScSa" },
    { text = { " ", "%l", " " }, click = "v:lua.ScLn" },
    { text = { " ", "%c", " " }, click = "v:lua.ScCo" },
  },
  relculright = true,
}

-- ===== Mini.indentscope: vạch indent theo scope =====
require("mini.indentscope").setup {
  draw = { animation = require("mini.indentscope").gen_animation.none() },
  symbol = "▏",
}

-- ===== Vim-illuminate: highlight từ cùng tên =====
require("vim-illuminate").configure {
  delay = 200,
  filetypes_denylist = { "Outline", "NvimTree", "qf" },
}
