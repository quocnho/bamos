-- Nvim-ufo: fold thông minh (ưu tiên LSP foldingRange → treesitter → indent).
vim.o.foldcolumn = "1"
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldenable = true

require("ufo").setup {
  provider_selector = function(_, filetype)
    local lspWithFolding = vim.tbl_filter(function(client)
      return client.name ~= "ruff" and client:supports_method("textDocument/foldingRange")
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
