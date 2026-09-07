-- Chế độ gõ INSERT kiểu EMACS — dành cho người quen phím Emacs khi soạn code/văn bản.
--
-- BẬT/TẮT: mặc định BẬT. Muốn tắt → thêm dòng sau vào `lua/bamos/globals.lua`:
--     vim.g.bamos_emacs_insert = false
--
-- PHỐI HỢP với completion (blink.cmp): các phím blink chiếm (C-b/C-f/C-k/C-y/C-e)
-- đã vô hiệu trong `lua/bamos/plugins/cmp.lua` → map emacs bên dưới hoạt động được.
-- C-p/C-n GIỮ NGUYÊN cho blink (chỉ có tác dụng khi menu completion đang mở).
if vim.g.bamos_emacs_insert == false then
    return
end

local keymap = vim.keymap

-- ====================== Con trỏ (giống Emacs) ======================
keymap.set("i", "<C-b>", "<Left>", { desc = "sang trái 1 ký tự" })
keymap.set("i", "<C-f>", "<Right>", { desc = "sang phải 1 ký tự" })
keymap.set("i", "<C-a>", "<Home>", { desc = "về đầu dòng" })
keymap.set("i", "<C-e>", "<End>", { desc = "về cuối dòng" })

-- ====================== Xoá / dán (kill & yank) ======================
keymap.set("i", "<C-d>", "<Del>", { desc = "xoá ký tự phía trước con trỏ" })
keymap.set("i", "<C-k>", "<C-o>D", { desc = "xoá (kill) tới cuối dòng" })
-- Dán lại (yank): lấy register " — thứ vừa kill/xoá
keymap.set("i", "<C-y>", "<C-r>\"", { desc = "dán (yank) nội dung vừa kill" })

-- ====================== Theo từ (giống Emacs) ======================
keymap.set("i", "<M-b>", "<C-o>b", { desc = "lùi về đầu từ" })
keymap.set("i", "<M-Left>", "<C-o>b", { desc = "lùi về đầu từ" })
keymap.set("i", "<M-f>", "<C-o>e", { desc = "tới cuối từ" })
keymap.set("i", "<M-Right>", "<C-o>e", { desc = "tới cuối từ" })
keymap.set("i", "<M-d>", "<C-o>de", { desc = "xoá (kill) hết từ phía trước" })

-- ====================== Giữ NGUYÊN vim (đã hợp emacs) ======================
--   <C-h>          xoá lùi 1 ký tự   (= xoá phím Backspace, emacs cũng vậy)
--   <C-w>          xoá lùi cả từ     (= emacs M-<backspace>)
--   <C-u>          xoá về đầu dòng   (vim chuẩn — tiện hơn emacs C-u)
--   <C-t>          thụt lề phải      (vim chuẩn, giữ cho lập trình viên)
--   <C-r>          chèn register     (vim — bổ sung cho C-y)
--
-- ĐÁNH ĐỔI (theo yêu cầu emacs):
--   • C-e  từ "chèn ký tự dòng trên" → cuối dòng        (chèn dòng trên: dùng <C-y> gốc đã mất)
--   • C-y  từ "chèn ký tự dòng trên/chọn completion" → dán (chọn item dùng <CR>/<Tab>)
--   • C-k  từ "digraph/signature help" → xoá tới cuối dòng (digraph: gõ unicode qua <C-v>u…)
--   • C-d  từ "thụt lề trái" → xoá ký tự phía trước     (thụt lề trái: Backspace ở đầu dòng)
--   • C-b/C-f từ "cuộn documentation" → di chuyển con trỏ
