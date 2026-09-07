-- Treesitter: grammar cài qua Nix (nvim-treesitter.withAllGrammars) → có sẵn
-- parser trong runtimepath, không tải lúc chạy.
--
-- nvim-treesitter 0.10 (mainline mới): KHÔNG còn auto-bật highlight/indent —
-- tự bật theo FileType khi có parser (vim.treesitter.start + indentexpr).
-- nvim-treesitter-textobjects (module): không tự map phím — map tay qua API
-- select/move/swap (xem bên dưới).

-- ====================== Highlight + indent theo FileType ======================
-- Chỉ bật khi parser của ngôn ngữ có sẵn (withAllGrammars) — pcall để file
-- không có parser (text, qf, help…) không gây lỗi.
local skip_ft = {
  qf = true, help = true, man = true, text = true, gitcommit = true,
  snacks_dashboard = true, aerial = true, NvimTree = true, oil = true,
}

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("bamos_treesitter", { clear = true }),
  callback = function(args)
    local ft = vim.bo[args.buf].filetype
    if ft == "" or skip_ft[ft] or vim.bo[args.buf].buftype ~= "" then
      return
    end
    local ok = pcall(vim.treesitter.start, args.buf)
    if ok then
      -- Indent treesitter (chỉ khi parser OK — nvim-treesitter cung cấp indentexpr)
      vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

-- ====================== Text objects (module mới — tự map tay) ======================
local select = require("nvim-treesitter-textobjects.select")
local move = require("nvim-treesitter-textobjects.move")
local swap = require("nvim-treesitter-textobjects.swap")

-- select: af/if (function), ac/ic (class), aa/ia (argument), ab/ib (block),
-- al/il (loop), at/it (conditional)
local select_keys = {
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
}
for lhs, capture in pairs(select_keys) do
  vim.keymap.set({ "x", "o" }, lhs, function()
    select.select_textobject(capture, "textobjects")
  end, { desc = "select " .. capture })
end

-- move: nhảy giữa các symbol ]f/]c (next) · [f/[c (prev) · ]F/]C/[F/[C (end)
local function goto_next_start(capture)
  return function()
    move.goto_next_start(capture, "textobjects")
  end
end
local function goto_next_end(capture)
  return function()
    move.goto_next_end(capture, "textobjects")
  end
end
local function goto_prev_start(capture)
  return function()
    move.goto_previous_start(capture, "textobjects")
  end
end
local function goto_prev_end(capture)
  return function()
    move.goto_previous_end(capture, "textobjects")
  end
end

for _, map in ipairs({
  { "]f", goto_next_start("@function.outer"), "next function" },
  { "]c", goto_next_start("@class.outer"), "next class" },
  { "]F", goto_next_end("@function.outer"), "next function end" },
  { "]C", goto_next_end("@class.outer"), "next class end" },
  { "[f", goto_prev_start("@function.outer"), "prev function" },
  { "[c", goto_prev_start("@class.outer"), "prev class" },
  { "[F", goto_prev_end("@function.outer"), "prev function end" },
  { "[C", goto_prev_end("@class.outer"), "prev class end" },
}) do
  vim.keymap.set({ "n", "x", "o" }, map[1], map[2], { desc = map[3] })
end

-- swap: đổi chỗ tham số ,a / ,A
vim.keymap.set("n", "<leader>a", function()
  swap.swap_next("@parameter.inner")
end, { desc = "swap param next" })
vim.keymap.set("n", "<leader>A", function()
  swap.swap_previous("@parameter.inner")
end, { desc = "swap param prev" })
