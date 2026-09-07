-- Treesitter: grammar cài qua Nix (nvim-treesitter.withAllGrammars) → không tải
-- lúc chạy, không cần compiler. Text objects theo cú pháp (af/if, ac/ic, aa/ia…).
--
-- LƯU Ý nvim-treesitter bản mới: dùng module `nvim-treesitter` nếu có (main
-- branch mới), fallback `configs.setup` cho bản cũ — tương thích cả hai.
local ok, ts = pcall(require, "nvim-treesitter")
if ok and ts.setup then
  ts.setup({
    highlight = { enable = true },
    indent = { enable = true },
  })
else
  require("nvim-treesitter.configs").setup({
    ensure_installed = {},
    highlight = { enable = true },
    indent = { enable = true },
  })
end

-- Text objects theo cú pháp: af/if (function), ac/ic (class), aa/ia (argument),
-- ab/ib (block), al/il (loop), at/it (conditional)…
require("nvim-treesitter-textobjects").setup({
  select = {
    enable = true,
    lookahead = true,
    keymaps = {
      ["af"] = "@function.outer",
      ["if"] = "@function.inner",
      ["ac"] = "@class.outer",
      ["ic"] = "@class.inner",
      ["aa"] = "@parameter.outer",
      ["ia"] = "@parameter.inner",
      ["ab"] = "@block.outer",
      ["ib"] = "@block.inner",
      ["al"] = "@loop.outer",
      ["il"] = "@loop.inner",
      ["at"] = "@conditional.outer",
      ["it"] = "@conditional.inner",
    },
  },
  swap = {
    enable = true,
    swap_next = { ["<leader>a"] = "@parameter.inner" },
    swap_previous = { ["<leader>A"] = "@parameter.inner" },
  },
  move = {
    enable = true,
    goto_next_start = { ["]f"] = "@function.outer", ["]c"] = "@class.outer" },
    goto_next_end = { ["]F"] = "@function.outer", ["]C"] = "@class.outer" },
    goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer" },
    goto_previous_end = { ["[F"] = "@function.outer", ["[C"] = "@class.outer" },
  },
})
