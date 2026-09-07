-- Fcitx5 + Unikey (gõ tiếng Việt): TỰ TẮT bộ gõ khi không nhập văn bản.
--
-- Cách dùng mong muốn: mặc định gõ TIẾNG ANH (code/lệnh); khi cần tiếng Việt
-- thì tự bật THỦ CÔNG bằng phím tắt fcitx5 (vd Ctrl+Space) trong insert mode.
--
-- Module này tự gọi `fcitx5-remote -c` (về trạng thái inactive = gõ tiếng Anh):
--   1. MỞ nvim (VimEnter)                    → không "dính" trạng thái app trước
--   2. RỜI insert về normal: Esc, Ctrl+C     → gõ phím lệnh không ra dấu
--   3. RỜI terminal (tiny-term: <C-/>…)      → như trên
--   4. VÀO command-line (: hoặc ; remap)     → gõ lệnh Ex không ra dấu
--   5. Mọi chuyển mode không còn ở insert/terminal (bao phủ mọi ngõ thoát)
--
-- An toàn: chỉ hoạt động trên Linux & khi có `fcitx5-remote` — máy không dùng
-- fcitx5, SSH/headless, CI… thì module tự bỏ qua. Gọi bất đồng bộ (jobstart),
-- không bao giờ block UI.
if vim.fn.has("unix") == 0 or vim.fn.has("macunix") == 1 or vim.fn.executable("fcitx5-remote") == 0 then
  return
end

local api = vim.api
local group = api.nvim_create_augroup("bamos_fcitx5_ime", { clear = true })

local function im_close()
  vim.fn.jobstart({ "fcitx5-remote", "-c" }, { detach = true })
end

-- 1) Mở nvim → chắc chắn đang gõ tiếng Anh
api.nvim_create_autocmd("VimEnter", { group = group, callback = im_close })

-- 2) Rời insert (Esc, và Ctrl+C qua remap bên dưới) → tắt IME
api.nvim_create_autocmd("InsertLeave", { group = group, callback = im_close })

-- 4) Vào command-line (kể cả qua phím `;` đã remap thành `:`) → tắt IME
api.nvim_create_autocmd("CmdlineEnter", { group = group, callback = im_close })

-- 3+5) Bao phủ mọi đường thoát khác (Ctrl+C, terminal <C-/> → normal, ...):
-- hễ không còn ở insert (i*) hay terminal (t*) thì tắt IME.
api.nvim_create_autocmd("ModeChanged", {
  group = group,
  pattern = "*:*",
  callback = function()
    local mode = vim.fn.mode():sub(1, 1)
    if mode ~= "i" and mode ~= "t" then
      im_close()
    end
  end,
})

-- Ctrl+C trong insert mặc định KHÔNG kích hoạt InsertLeave → remap thành <Esc>
-- để việc tắt IME luôn chạy (tương đương Esc, không đổi hành vi khác).
vim.keymap.set("i", "<C-c>", "<Esc>", { desc = "Ctrl+C = Esc (để tự tắt IME)" })
