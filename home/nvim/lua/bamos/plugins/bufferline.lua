-- Bufferline — thanh tab kiểu IDE (giống look LazyVim: icon file, vạch active,
-- đóng bằng icon, hiện số diagnostic).
require("bufferline").setup {
  options = {
    mode = "buffers",
    -- Số thứ tự buffer trên tab (như IDE) — muốn bỏ: "none"
    numbers = "ordinal",
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
    always_show_bufferline = true,
    -- Không hiện buffer đặc biệt (dashboard, help…) trên tab bar
    custom_filter = function(buf, buf_nums)
      local ft = vim.bo[buf].filetype
      if ft == "snacks_dashboard" or ft == "help" or vim.bo[buf].buftype ~= "" then
        return false
      end
      return true
    end,
  },
}

-- Phím tắt chuyển tab buffer
local map = vim.keymap.set
map("n", "<Tab>", "<cmd>BufferLineCycleNext<CR>", { desc = "next buffer" })
map("n", "<S-Tab>", "<cmd>BufferLineCyclePrev<CR>", { desc = "prev buffer" })
