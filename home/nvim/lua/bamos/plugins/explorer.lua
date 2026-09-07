-- File explorer: nvim-tree (sidebar kiểu IDE — giống look LazyVim/neo-tree).
-- Muốn explorer kiểu "oil" (nhẹ nhất): cài oil-nvim trong home/dev.nix +
-- thay config dưới — xem comment cuối file.
require("nvim-tree").setup {
  view = {
    width = 32,
    side = "left",
  },
  renderer = {
    root_folder_label = false,
    indent_markers = { enable = true },
    icons = {
      show = { file = true, folder = true, git = true },
    },
  },
  filters = {
    dotfiles = false,
    custom = { "^.git$", "node_modules", "result" },
  },
  update_focused_file = { enable = true },
}

local map = vim.keymap.set
map("n", "<space>s", "<cmd>NvimTreeToggle<CR>", { desc = "toggle nvim-tree" })
map("n", "<space>sf", "<cmd>NvimTreeFindFile<CR>", { desc = "tree tại file hiện tại" })

-- Thay bằng oil.nvim (nếu muốn nhẹ hơn nữa):
--   require("oil").setup { default_file_explorer = true }
--   map("n", "<space>s", "<cmd>Oil<CR>", { desc = "open parent (oil)" })
--   map("n", "<space>sf", "<cmd>Oil --float<CR>", { desc = "oil tại file (float)" })
