-- Treesitter — highlight + indent.
-- Grammar CÀI QUA NIX (nvim-treesitter.withAllGrammars) → không tải lúc chạy,
-- không cần compiler trên máy (đúng tinh thần "cài xong là dùng" của BamOS).
local ok, ts = pcall(require, "nvim-treesitter")
if ok and ts.setup then
  -- API mới (nvim-treesitter >= 0.9)
  ts.setup({
    highlight = { enable = true },
    indent = { enable = true },
  })
else
  -- API cũ (fallback)
  require("nvim-treesitter.configs").setup({
    ensure_installed = {}, -- đã có sẵn qua withAllGrammars
    highlight = { enable = true },
    indent = { enable = true },
  })
end
