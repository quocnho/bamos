-- TypeScript / JavaScript (ts_ls)
vim.lsp.config("ts_ls", {
  settings = {
    typescript = { inlayHints = { parameterNames = { enabled = "all" } } },
    javascript = { inlayHints = { parameterNames = { enabled = "all" } } },
  },
})
