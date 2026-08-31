-- Keymaps (port từ lua/mappings.lua của jdhao — các phím autoload được viết
-- lại inline bằng Lua để không phụ thuộc file autoload/*.vim).
local keymap = vim.keymap.set
local uv = vim.uv

-- ====================== Cơ bản ======================
-- Gõ ";" thay ":" để vào command mode (tiết kiệm phím shift)
keymap.set({ "n", "x" }, ";", ":")

-- Chuyển chữ dưới con trỏ: UPPER / Title
keymap.set("i", "<c-u>", "<Esc>viwUea")
keymap.set("i", "<c-t>", "<Esc>b~lea")

-- Paste không linewise lên/xuống dòng hiện tại
keymap.set("n", "<leader>p", "m`o<ESC>p``", { desc = "paste below" })
keymap.set("n", "<leader>P", "m`O<ESC>p``", { desc = "paste above" })

-- Lưu / thoát
keymap.set("n", "<leader>w", "<cmd>update<cr>", { silent = true, desc = "save buffer" })
keymap.set("n", "<leader>q", "<cmd>x<cr>", { silent = true, desc = "save and quit" })
keymap.set("n", "<leader>Q", "<cmd>qa!<cr>", { silent = true, desc = "quit nvim" })

-- Đóng quickfix / location list
keymap.set("n", [[\x]], "<cmd>windo lclose <bar> cclose <cr>", { silent = true, desc = "close qf/loc list" })

-- Xoá buffer (giữ cửa sổ); xoá các buffer khác
keymap.set("n", [[\db]], "<cmd>bprevious <bar> bdelete #<cr>", { silent = true, desc = "delete buffer" })
keymap.set("n", [[\dB]], function()
  local buf_ids = vim.api.nvim_list_bufs()
  local cur_buf = vim.api.nvim_win_get_buf(0)
  for _, buf_id in ipairs(buf_ids) do
    if vim.api.nvim_get_option_value("buflisted", { buf = buf_id }) and buf_id ~= cur_buf then
      vim.api.nvim_buf_delete(buf_id, { force = true })
    end
  end
end, { desc = "delete other buffers" })

keymap.set("n", [[\dt]], "<cmd>tabclose<CR>", { silent = true, desc = "delete tab" })
keymap.set("n", [[\dT]], "<cmd>tabonly<CR>", { silent = true, desc = "delete other tabs" })

-- Di chuyển theo dòng hiển thị (wrap-aware)
keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true })
keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true })
keymap.set("n", "^", "g^")
keymap.set("n", "0", "g0")
keymap.set("x", "$", "g_")

-- Đầu/cuối dòng dễ hơn
keymap.set({ "n", "x" }, "H", "^")
keymap.set({ "n", "x" }, "L", "g_")

-- Shift liên tục trong visual (giữ selection)
keymap.set("x", "<", "<gv")
keymap.set("x", ">", ">gv")

-- Chọn lại vùng vừa dán
keymap.set("n", "<leader>v", "`[V`]", { desc = "reselect pasted" })

-- Đổi cwd theo file hiện tại
keymap.set("n", "<leader>cd", "<cmd>lcd %:p:h<cr><cmd>pwd<cr>", { desc = "change cwd to file dir" })

-- Esc thoát terminal
keymap.set("t", "<Esc>", [[<c-\><c-n>]])

-- Toggle spell check
keymap.set("n", "<F11>", "<cmd>set spell!<cr>", { desc = "toggle spell" })
keymap.set("i", "<F11>", "<c-o><cmd>set spell!<cr>", { desc = "toggle spell" })

-- c/C không làm bẩn register
keymap.set("n", "c", '"_c')
keymap.set("n", "C", '"_C')
keymap.set("n", "cc", '"_cc')
keymap.set("x", "c", '"_c')

-- Copy toàn bộ buffer / xoá trailing space
keymap.set("n", "<leader>y", "<cmd>%yank<cr>", { desc = "yank whole buffer" })
keymap.set("n", "<leader><space>", "<cmd>StripTrailingWhitespace<cr>", { desc = "strip trailing spaces" })

-- Toggle cursor column highlight
keymap.set("n", "<leader>cl", function()
  vim.opt.cursorcolumn = not vim.opt.cursorcolumn:get()
end, { desc = "toggle cursor column" })

-- Di chuyển dòng/khối lên xuống
keymap.set("n", "<A-k>", function()
  if vim.fn.line(".") == 1 then
    return
  end
  vim.cmd("normal! ddP")
end, { desc = "move line up" })
keymap.set("n", "<A-j>", function()
  if vim.fn.line(".") == vim.fn.line("$") then
    return
  end
  vim.cmd("normal! ddp")
end, { desc = "move line down" })
keymap.set("x", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "move selection up" })
keymap.set("x", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "move selection down" })

-- Dán từ register không làm bẩn register
keymap.set("x", "p", '"_c<Esc>p')

-- Chuyển buffer: gb/gB (đếm số)
keymap.set("n", "gb", function()
  vim.cmd("bnext")
end, { desc = "next buffer" })
keymap.set("n", "gB", function()
  vim.cmd("bprevious")
end, { desc = "previous buffer" })

-- Điều hướng cửa sổ bằng phím mũi tên
keymap.set("n", "<left>", "<c-w>h")
keymap.set("n", "<Right>", "<C-W>l")
keymap.set("n", "<Up>", "<C-W>k")
keymap.set("n", "<Down>", "<C-W>j")

-- J không nhảy con trỏ
keymap.set("n", "J", function()
  vim.cmd("normal! mzJ`z")
  vim.cmd("delmarks z")
end, { desc = "join lines (keep cursor)" })

-- Tách undo unit theo dấu câu
for _, ch in ipairs({ ",", ".", "!", "?", ";", ":" }) do
  keymap.set("i", ch, ch .. "<c-g>u")
end

-- Chèn dấu ";" cuối dòng
keymap.set("i", "<A-;>", "<Esc>miA;<Esc>`ii")

-- Điều hướng trong insert/command
keymap.set("i", "<C-A>", "<HOME>")
keymap.set("i", "<C-E>", "<END>")
keymap.set("c", "<C-A>", "<HOME>")
keymap.set("i", "<C-D>", "<DEL>")

-- Nhấn nháy vị trí con trỏ (tìm nhanh)
keymap.set("n", "<leader>cb", function()
  local cnt, blink_times = 0, 7
  local timer = uv.new_timer()
  if timer == nil then
    return
  end
  timer:start(0, 100, vim.schedule_wrap(function()
    vim.cmd("set cursorcolumn! | set cursorline!")
    cnt = cnt + 1
    if cnt == blink_times then
      timer:close()
    end
  end))
end, { desc = "blink cursor" })

-- Ghi macro bằng Q (q hiển thị thông báo)
keymap.set("n", "q", function()
  vim.print("q đã remap sang Q — dùng Q để ghi macro!")
end)
keymap.set("n", "Q", "q", { desc = "record macro" })

-- Esc đóng cửa sổ nổi
keymap.set("n", "<Esc>", function()
  vim.cmd("fclose!")
end, { desc = "close floating window" })
