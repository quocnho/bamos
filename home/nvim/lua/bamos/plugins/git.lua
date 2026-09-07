-- Git: gitsigns (dấu thay đổi) + fugitive (:Git) + lazygit qua snacks (<space>gg).
-- UI diff/log nâng cao cứ dùng lazygit — gọn hơn diffview.

-- ===== Gitsigns: dấu thay đổi bên lề + keymaps =====
require("gitsigns").setup {
  signs = {
    add = { text = "+" },
    change = { text = "~" },
    delete = { text = "_" },
    topdelete = { text = "‾" },
    changedelete = { text = "~" },
  },
  current_line_blame = false, -- đổi true để xem blame tại dòng
  on_attach = function(bufnr)
    local map = function(mode, l, r, opts)
      opts = opts or {}
      opts.buffer = bufnr
      vim.keymap.set(mode, l, r, opts)
    end
    -- ]h/[h = hunk (chuẩn LazyVim); ]c/[c để dành cho treesitter-textobjects
    -- (nhảy class) — xem plugins/treesitter.lua. Trong diff vẫn dùng ]c/[c gốc.
    map("n", "]h", "&diff ? ']c' : '<cmd>Gitsigns next_hunk<CR>'", { expr = true })
    map("n", "[h", "&diff ? '[c' : '<cmd>Gitsigns prev_hunk<CR>'", { expr = true })
    map("n", "<leader>gp", "<cmd>Gitsigns preview_hunk<CR>", { desc = "preview hunk" })
    map("n", "<leader>gr", "<cmd>Gitsigns reset_hunk<CR>", { desc = "reset hunk" })
    map("n", "<leader>gs", "<cmd>Gitsigns stage_hunk<CR>", { desc = "stage hunk" })
  end,
}

-- ===== Fugitive: git nhanh trong nvim (:Git) =====
local map = vim.keymap.set
map("n", "<space>gv", "<cmd>Git<CR>", { desc = "git status (fugitive)" })
map("n", "<space>gd", "<cmd>Gvdiffsplit<CR>", { desc = "git diff split" })
map("n", "<space>gl", "<cmd>Gclog<CR>", { desc = "git log" })
map("n", "<space>gb", "<cmd>Git blame<CR>", { desc = "git blame" })
map("n", "<space>gy", "<cmd>GBrowse<CR>", { desc = "mở file/dòng trên GitHub" })
map("x", "<space>gy", "<cmd>GBrowse<CR>", { desc = "mở selection trên GitHub" })
