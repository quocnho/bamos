-- Ruff (lint + format cho Python) — port after/lsp/ruff.lua của jdhao
vim.lsp.config("ruff", {
  settings = {
    ruff = {
      lineLength = 100,
      lint = { enable = true },
      format = { enable = true },
    },
  },
})
