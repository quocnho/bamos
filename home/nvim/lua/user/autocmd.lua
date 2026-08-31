-- Autocommands (theo tinh thần lua/custom-autocmd.lua của jdhao — rút gọn).
local api = vim.api
local augroup = api.nvim_create_augroup("bamos", { clear = true })

-- ====================== Format khi lưu (LSP) ======================
-- Chỉ format các filetype có LSP server đang chạy (server từ Nix hoặc devenv).
-- Muốn tắt: xoá filetype khỏi danh sách dưới.
local format_on_save_ft = {
  python = true, lua = true, nix = true,
  typescript = true, javascript = true, typescriptreact = true, javascriptreact = true,
  go = true, rust = true, c = true, cpp = true,
  json = true, yaml = true, markdown = true, sh = true,
}

api.nvim_create_autocmd("BufWritePre", {
  group = augroup,
  pattern = "*",
  callback = function(args)
    local ft = vim.bo[args.buf].filetype
    if not format_on_save_ft[ft] then
      return
    end
    if vim.lsp.buf_get_clients(args.buf) == nil or vim.lsp.buf_get_clients(args.buf)[1] == nil then
      return
    end
    vim.lsp.buf.format({ bufnr = args.buf, async = true })
  end,
})

-- ====================== Nhớ vị trí con trỏ khi mở lại file ======================
api.nvim_create_autocmd({ "BufReadPost" }, {
  group = augroup,
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    local lcount = vim.api.nvim_buf_line_count(args.buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- ====================== Tự cân chỉnh cửa sổ khi resize ======================
api.nvim_create_autocmd("VimResized", {
  group = augroup,
  callback = function()
    vim.cmd("tabdo wincmd =")
  end,
})

-- ====================== Highlight vùng vừa yank ======================
api.nvim_create_autocmd("TextYankPost", {
  group = augroup,
  callback = function()
    vim.hl.on_yank({ timeout = 200 })
  end,
})

-- ====================== Lệnh: xoá khoảng trắng cuối dòng ======================
api.nvim_create_user_command("StripTrailingWhitespace", function()
  local save = vim.fn.winsaveview()
  vim.cmd([[%s/\s\+$//e]])
  vim.fn.winrestview(save)
end, { desc = "Strip trailing whitespace" })
