-- Completion: blink.cmp (nhanh, gọn — thay toàn bộ stack nvim-cmp).
-- Sources: LSP + snippets (friendly-snippets qua luasnip) + path + buffer.
local blink = require("blink.cmp")

blink.setup {
    keymap = {
        preset = "default",
        -- LƯU Ý: các phím C-e/C-b/C-f/C-k/C-y bị vô hiệu (false) để nhường cho chế
        -- độ INSERT KIỂU EMACS (xem lua/bamos/emacs.lua). Chọn item trong menu vẫn
        -- dùng <CR>/<Tab>; C-p/C-n chỉ điều hướng khi menu ĐANG mở.
        ["<C-Space>"] = { "show", "hide" },
        ["<C-e>"] = false, -- emacs: End
        ["<C-b>"] = false, -- emacs: sang trái
        ["<C-f>"] = false, -- emacs: sang phải
        ["<C-k>"] = false, -- emacs: xoá tới cuối dòng
        ["<C-y>"] = false, -- emacs: dán (yank)
        ["<CR>"] = { "accept", "fallback" },
        ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
    },
    appearance = {
        use_nvim_cmp_as_default = false,
        nerd_font_variant = "mono",
    },
    sources = {
        default = { "lsp", "snippets", "path", "buffer" },
        per_filetype = {
            markdown = { "snippets", "path", "buffer" },
        },
    },
    snippets = {
        preset = "luasnip",
    },
    completion = {
        documentation = { auto_show = true },
        menu = {
            draw = {
                columns = {
                    { "kind_icon" },
                    { "label",    "label_description" },
                    { "kind" },
                },
                components = {
                    kind_icon = {
                        ellipsis = false,
                        text = function(ctx)
                            return ctx.kind_icon .. ctx.icon_gap
                        end,
                        highlight = function(ctx)
                            return "BlinkCmpKind" .. ctx.kind
                        end,
                    },
                },
            },
        },
    },
}
