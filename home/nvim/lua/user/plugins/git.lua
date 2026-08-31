-- Git: gitsigns + fugitive + diffview + gitlinker (port lua/config/* của jdhao).

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
    map("n", "]c", "&diff ? ']c' : '<cmd>Gitsigns next_hunk<CR>'", { expr = true })
    map("n", "[c", "&diff ? '[c' : '<cmd>Gitsigns prev_hunk<CR>'", { expr = true })
    map("n", "<leader>gp", "<cmd>Gitsigns preview_hunk<CR>", { desc = "preview hunk" })
    map("n", "<leader>gr", "<cmd>Gitsigns reset_hunk<CR>", { desc = "reset hunk" })
    map("n", "<leader>gs", "<cmd>Gitsigns stage_hunk<CR>", { desc = "stage hunk" })
  end,
}

-- ===== Fugitive: git trong nvim =====
local map = vim.keymap.set
map("n", "<space>gv", "<cmd>Git<CR>", { desc = "git status (fugitive)" })
map("n", "<space>gd", "<cmd>Gvdiffsplit<CR>", { desc = "git diff split" })
map("n", "<space>gl", "<cmd>Gclog<CR>", { desc = "git log" })
map("n", "<space>gb", "<cmd>Git blame<CR>", { desc = "git blame" })

-- ===== Diffview: UI diff/log đẹp =====
require("diffview").setup {}
map("n", "<space>gD", "<cmd>DiffviewOpen<CR>", { desc = "diffview open" })
map("n", "<space>gL", "<cmd>DiffviewFileHistory<CR>", { desc = "diffview file history" })
map("n", "<space>gX", "<cmd>DiffviewClose<CR>", { desc = "diffview close" })

-- ===== Gitlinker: copy link file/dòng (github/gitlab) =====
require("gitlinker").setup {
  callbacks = {
    ["github.com"] = require("gitlinker.actions").get_github_type_url,
  },
}
map("n", "<space>gy", "<cmd>GitLink<CR>", { desc = "copy github link" })
map("x", "<space>gy", "<cmd>GitLink<CR>", { desc = "copy github link" })
