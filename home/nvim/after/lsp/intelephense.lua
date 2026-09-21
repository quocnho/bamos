-- Intelephense (PHP / Laravel / CodeIgniter)
-- LSP này sẽ được kích hoạt khi có binary intelephense trong PATH (hoặc từ devenv.nix)
return {
  settings = {
    intelephense = {
      files = {
        maxSize = 5000000,
      },
      environment = {
        phpVersion = "8.3",
      },
      completion = {
        insertUseDeclaration = true,
        fullyQualifyGlobalConstantsAndFunctions = false,
      },
    },
  },
}
