-- Nil — Nix language server (đặc trưng NixOS; dùng chung với Zed/Antigravity)
vim.lsp.config("nil_ls", {
  settings = {
    ["nil"] = {
      formatting = {
        command = { "nixfmt" }, -- format qua nixfmt (có sẵn trong extraPackages)
      },
      nix = {
        maxMemoryMB = 4096,
        flake = { autoEvalInputs = true },
      },
    },
  },
})
