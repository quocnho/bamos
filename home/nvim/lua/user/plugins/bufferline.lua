-- Bufferline — thanh tab kiểu IDE (port lua/config/bufferline.lua của jdhao).
require("bufferline").setup {
  options = {
    mode = "buffers",
    diagnostics = "nvim_lsp",
    diagnostics_indicator = function(_, _, diagnostics_dict, _)
      local result = ""
      local s = { error = "🆇", warn = "⚠️" }
      for e, n in pairs(diagnostics_dict) do
        result = result .. " " .. (s[e] or e) .. n
      end
      return result
    end,
    show_buffer_close_icons = true,
    show_close_icon = false,
    separator_style = "thin",
    always_show_bufferline = false,
  },
}

-- Phím tắt chuyển tab buffer
local map = vim.keymap.set
map("n", "<Tab>", "<cmd>BufferLineCycleNext<CR>", { desc = "next buffer" })
map("n", "<S-Tab>", "<cmd>BufferLineCyclePrev<CR>", { desc = "prev buffer" })
