-- Lualine — statusline (port lua/config/lualine.lua của jdhao, rút gọn).
local utils = require("user.utils")

local function lsp_name()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then
    return ""
  end
  local names = {}
  for _, client in ipairs(clients) do
    table.insert(names, client.name)
  end
  return table.concat(names, ",")
end

require("lualine").setup {
  options = {
    theme = "auto", -- theo colorscheme đang chạy (jdhao style)
    globalstatus = true,
    icons_enabled = true,
    component_separators = { left = "", right = "" },
    section_separators = { left = "", right = "" },
    disabled_filetypes = { statusline = { "dashboard", "alpha" } },
  },
  sections = {
    lualine_a = { "mode" },
    lualine_b = { { "branch", icon = "" }, { "diff" }, { "diagnostics" } },
    lualine_c = {
      { "filename", path = 1, symbols = { modified = "●", readonly = "" } },
    },
    lualine_x = {
      { lsp_name, icon = "" },
      { "filetype", icon = "" },
      { "encoding" },
      { "fileformat" },
    },
    lualine_y = { { "progress" }, { "location" } },
    lualine_z = { "os.date('%H:%M')" },
  },
  inactive_sections = {
    lualine_a = { "filename" },
    lualine_b = {},
    lualine_c = {},
    lualine_x = {},
    lualine_y = {},
    lualine_z = {},
  },
}

-- Có dùng được cho LSP name nếu cần
vim.g.lualine_lsp_name = lsp_name
