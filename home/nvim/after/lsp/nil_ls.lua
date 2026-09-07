-- Nil — Nix language server (đặc trưng NixOS; dùng chung với Zed/Antigravity)
return {
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
}
