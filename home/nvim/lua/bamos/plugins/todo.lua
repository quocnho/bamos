-- Todo-comments (folke): highlight TODO/FIXME/HACK... + đẩy vào quickfix.
-- Hỗ trợ developer: không bỏ sót việc còn dang dở trong code.
require("todo-comments").setup {
  highlight = { multiline = true },
  search = { pattern = [[\b(?:TODO|FIXME|HACK|WARN|NOTE|PERF|BUG|XXX|BAM)\b]] },
}

local map = vim.keymap.set
-- Tìm todo bằng fzf-lua (có sẵn) — fallback quickfix: :TodoQuickFix
map("n", "<space>T", "<cmd>TodoFzfLua<CR>", { desc = "tìm todo comments (fzf)" })
-- Loclist theo buffer: :TodoLocList (chạy thủ công khi cần)
