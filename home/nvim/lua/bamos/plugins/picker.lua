-- Fzf-lua — fuzzy finder chính (nhẹ hơn telescope; ray-x cũng dùng fzf-lua).
-- Backend: fzf + fd + ripgrep (cài qua programs.neovim.extraPackages).
local fzf = require("fzf-lua")

fzf.setup {
  winopts = {
    height = 0.85,
    width = 0.85,
    preview = { horizontal = "right:55%" },
  },
  fzf_colors = true,
  files = {
    fd_opts = "--color=never --type f --hidden --follow --exclude .git --exclude node_modules --exclude result",
  },
}

local map = vim.keymap.set
map("n", "<space>ff", "<cmd>FzfLua files<CR>", { desc = "find files" })
map("n", "<space>fg", "<cmd>FzfLua grep<CR>", { desc = "live grep" })
map("n", "<space>fb", "<cmd>FzfLua buffers<CR>", { desc = "buffers" })
map("n", "<space>fr", "<cmd>FzfLua oldfiles<CR>", { desc = "recent files" })
map("n", "<space>fh", "<cmd>FzfLua help_tags<CR>", { desc = "help tags" })
map("n", "<space>fq", "<cmd>FzfLua quickfix<CR>", { desc = "quickfix list" })
map("n", "<space>f;", "<cmd>FzfLua commands<CR>", { desc = "commands" })
map("n", "<space>fp", "<cmd>FzfLua git_files<CR>", { desc = "git files" })
map("n", "<space>fc", "<cmd>FzfLua git_commits<CR>", { desc = "git commits" })
