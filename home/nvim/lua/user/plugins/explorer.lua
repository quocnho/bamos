-- Khám phá file & fold: nvim-tree + nvim-ufo (port lua/config/* của jdhao).

-- ===== Nvim-tree: file explorer =====
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

vim.keymap.set("n", "<space>s", "<cmd>NvimTreeToggle<CR>", { desc = "toggle nvim-tree" })
vim.keymap.set("n", "<space>sf", "<cmd>NvimTreeFindFile<CR>", { desc = "tree tại file hiện tại" })

-- ===== Nvim-ufo: fold thông minh theo LSP/treesitter =====
vim.o.foldcolumn = "1"
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldenable = true

require("ufo").setup {
  provider_selector = function(_, filetype)
    local lspWithFolding = vim.tbl_filter(function(client)
      return client.name ~= "ruff" and client.supports_method("textDocument/foldingRange")
    end, vim.lsp.get_clients({ buftype = { "nofile" }, filetype = filetype }))
    if #lspWithFolding > 0 then
      return { "lsp", "indent" }
    end
    return { "treesitter", "indent" }
  end,
}

local map = vim.keymap.set
map("n", "<space>zR", function()
  require("ufo").openAllFolds()
end, { desc = "mở mọi fold" })
map("n", "<space>zM", function()
  require("ufo").closeAllFolds()
end, { desc = "đóng mọi fold" })
map("n", "<space>zr", function()
  require("ufo").openFoldsOverCursorLine()
end, { desc = "mở fold ở con trỏ" })
map("n", "<space>zm", function()
  require("ufo").closeFoldsWith()
end, { desc = "đóng fold ở con trỏ" })
