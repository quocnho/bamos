-- YAML (yamlls)
vim.lsp.config("yamlls", {
  settings = {
    yaml = {
      schemaStore = { enable = true },
      format = { enable = true },
    },
  },
})
