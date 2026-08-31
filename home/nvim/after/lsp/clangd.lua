-- Clangd (C/C++) — port after/lsp/clangd.lua của jdhao
vim.lsp.config("clangd", {
  cmd = { "clangd", "--background-index", "--clang-tidy", "--header-insertion=iwyu" },
})
