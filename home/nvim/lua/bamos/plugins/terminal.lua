-- Terminal: tiny-term.nvim (jellydn) — float/split toggle, Snacks.terminal-compatible.
-- Nhẹ (0 dependency), đa terminal theo count, double-Esc vào normal.
local tiny = require("tiny-term")

tiny.setup {
  -- Shell mặc định (zsh trên BamOS)
  shell = vim.o.shell,
  win = {
    -- Không có lệnh → bottom split; có lệnh → float (mặc định plugin)
    split_size = 12,
    stack = true,
  },
  start_insert = true,
  auto_insert = true,
  auto_close = true,
}

local map = vim.keymap.set

-- Nhóm <space>t = terminal (không map `<space>t` đơn để tránh delay với tt/tf)
map("n", "<space>tt", function()
  tiny.toggle()
end, { desc = "toggle terminal (bottom)" })
map("n", "<space>tf", function()
  tiny.toggle(nil, { win = { position = "float" } })
end, { desc = "terminal nổi" })

-- Toggle nhanh: <C-/> (2<C-/> = terminal #2).
-- LƯU Ý: trong Vim <C-/> và <C-_> là CÙNG keycode (0x1F) — chỉ map MỘT phím
-- kèm xử lý count, không map cả hai (tự đè nhau).
map("n", "<C-/>", function()
  tiny.toggle(nil, { count = vim.v.count1 })
end, { desc = "toggle terminal (count)" })

-- Command có sẵn: :TinyTerm, :TinyTermOpen {cmd}, :TinyTermClose, :TinyTermList
