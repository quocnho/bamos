-- Keymaps toàn cục (core). Keymaps theo plugin nằm ở lua/bamos/plugins/*.
-- Mọi map có `desc` → which-key tự nhận diện (which-key v3).
local keymap = vim.keymap

-- ====================== Cơ bản ======================
-- Gõ ";" thay ":" để vào command mode (tiết kiệm phím shift)
keymap.set({ "n", "x" }, ";", ":")

-- LƯU Ý: giữ NGUYÊN các phím insert-mode chuẩn của vim (hữu ích cho dev):
--   <C-u> xoá về đầu dòng • <C-t>/<C-d> thụt lề • <C-a> lặp chèn • <C-e> chèn
--   ký tự dòng trên — không remap sang chức năng khác như cấu hình cũ.

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

-- ESC trong terminal: để tiny-term lo (double-Esc mới thoát, single Esc truyền
-- qua — xem plugins/terminal.lua).

-- Esc ở normal: đóng cửa sổ nổi nếu đang mở (an toàn hơn `fclose!` cũ)
keymap.set("n", "<Esc>", function()
    if vim.api.nvim_win_get_config(0).relative ~= "" then
        vim.cmd("close!")
    end
end, { desc = "close floating window" })

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

-- Dán từ register không làm bẩn register — KHÔNG map x-p ở đây nữa:
-- visual p/P do yanky đảm nhiệm (plugins/editor.lua, xử lý ring tốt hơn).

-- Chuyển buffer: gb/gB
keymap.set("n", "gb", "<cmd>bnext<CR>", { desc = "next buffer" })
keymap.set("n", "gB", "<cmd>bprevious<CR>", { desc = "previous buffer" })

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

-- Điều hướng trong insert giữ mặc định; command-line map Home/End:
keymap.set("c", "<C-A>", "<HOME>")
keymap.set("c", "<C-E>", "<END>")

-- Scroll wheel (tham khảo Nv/appelgriebsch): tắt cuộn NGANG; Shift+cuộn dọc
-- chuyển thành cuộn ngang — tránh vô tình cuộn ngang khi gõ phím cuộn.
keymap.set("n", "<ScrollWheelRight>", "<Nop>")
keymap.set("n", "<ScrollWheelLeft>", "<Nop>")
keymap.set("n", "<S-ScrollWheelUp>", "<ScrollWheelRight>")
keymap.set("n", "<S-ScrollWheelDown>", "<ScrollWheelLeft>")

-- Ghi macro: q mặc định (vim chuẩn); Q lặp lại macro vừa ghi ở thanh ghi q
-- (không chặn q như cấu hình cũ — q còn dùng đóng cửa sổ quickfix/help)
keymap.set("n", "Q", "@q", { desc = "lặp macro q" })
