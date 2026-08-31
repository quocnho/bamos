-- Completion: blink.cmp (mặc định của jdhao — thay nvim-cmp).
-- Sources: LSP + snippets (friendly-snippets qua luasnip) + path + buffer.
local blink = require("blink.cmp")

blink.setup {
  keymap = {
    preset = "default",
    ["<C-Space>"] = { "show", "hide" },
    ["<C-e>"] = { "hide" },
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
          { "label", "label_description" },
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
