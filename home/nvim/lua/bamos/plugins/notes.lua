-- Ghi chú nhanh: my-note.nvim (jellydn) — note markdown trong cửa sổ nổi,
-- riêng theo project (thư mục git) + file global. Cần nui.nvim (cài trong dev.nix).
require("my-note").setup {
  files = {
    -- Note theo project: lưu trong thư mục .git của dự án đang mở
    cwd = function()
      local buf_path = vim.api.nvim_buf_get_name(0)
      local dir = buf_path ~= "" and vim.fn.fnamemodify(buf_path, ":h") or vim.fn.getcwd()
      return vim.fs.root(dir, ".git") or vim.fn.getcwd()
    end,
  },
}

-- `,n` (leader) — mở ghi chú nhanh (giống flote: M dòng ghi chú cá nhân)
vim.keymap.set("n", "<leader>n", "<cmd>MyNote<CR>", { desc = "ghi chú nhanh (MyNote)" })
