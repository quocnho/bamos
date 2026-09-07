-- File explorer: oil.nvim (chuẩn LazyVim/tiny-nvim hiện đại — sửa filesystem
-- như buffer, nhẹ hơn nvim-tree). Muốn sidebar cũ: cài nvim-tree-lua trong
-- home/dev.nix + bỏ comment khối config ở cuối file.
require("oil").setup {
  default_file_explorer = true, -- thay netrw (đã tắt ở bamos/globals.lua)
  columns = { "icon" },
  view_options = {
    show_hidden = true,
  },
  float = {
    padding = 2,
    border = "rounded",
  },
  win_options = {
    wrap = false,
    signcolumn = "no",
    cursorcolumn = false,
    foldcolumn = "0",
    spell = false,
    list = false,
    conceallevel = 0,
  },
}

local map = vim.keymap.set
map("n", "<space>s", "<cmd>Oil<CR>", { desc = "explorer (oil — thư mục cha)" })
map("n", "<space>e", "<cmd>Oil --float<CR>", { desc = "explorer nổi (oil)" })

-- ===== Nếu thích sidebar kiểu nvim-tree (cách cũ) =====
-- require("nvim-tree").setup {
--   view = { width = 32, side = "left" },
--   renderer = {
--     root_folder_label = false,
--     indent_markers = { enable = true },
--     icons = { show = { file = true, folder = true, git = true } },
--   },
--   filters = { dotfiles = false, custom = { "^.git$", "node_modules", "result" } },
--   update_focused_file = { enable = true },
-- }
-- map("n", "<space>s", "<cmd>NvimTreeToggle<CR>", { desc = "toggle nvim-tree" })
-- map("n", "<space>sf", "<cmd>NvimTreeFindFile<CR>", { desc = "tree tại file hiện tại" })
