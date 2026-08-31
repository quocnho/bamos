-- Gopls (Go) — port after/lsp/gopls.lua của jdhao
vim.lsp.config("gopls", {
  settings = {
    gopls = {
      usePlaceholders = true,
      staticcheck = true,
      analyses = {
        unusedparams = true,
      },
    },
  },
})
