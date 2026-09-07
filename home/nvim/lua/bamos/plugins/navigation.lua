-- Điều hướng: aerial (outline) + hop (nhảy nhanh) + hlslens (đếm match tìm kiếm).

-- ===== Aerial: outline symbol (sidebar phải, kiểu minimap) =====
require("aerial").setup {
  layout = { default_direction = "right" },
  show_guides = true,
}
vim.keymap.set("n", "<space>o", "<cmd>AerialToggle<CR>", { desc = "toggle outline (aerial)" })

-- ===== Hop: nhảy nhanh bằng 2 ký tự (như EasyMotion) =====
require("hop").setup {
  keys = "etovxqpdygfblzhckisrimaunWETOVXQPDYGFBLZHCKRISRIMAUN",
}
local hop_map = vim.keymap.set
hop_map("n", "<space>hh", "<cmd>HopChar2<CR>", { desc = "hop char2" })
hop_map("n", "<space>hw", "<cmd>HopWord<CR>", { desc = "hop word" })
hop_map("n", "<space>hl", "<cmd>HopLine<CR>", { desc = "hop line" })
hop_map("n", "<space>hp", "<cmd>HopPattern<CR>", { desc = "hop pattern" })

-- ===== Hlslens: hiện số/thanh match khi tìm kiếm =====
require("hlslens").setup {}
local hl_map = vim.keymap.set
hl_map("n", "n", [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]], { desc = "next match" })
hl_map("n", "N", [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]], { desc = "prev match" })
