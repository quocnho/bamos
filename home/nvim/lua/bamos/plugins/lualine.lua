-- Lualine — statusline (theme "auto" theo colorscheme đang chạy).
local utils = require("bamos.utils")

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

local function py_env()
  local env = utils.get_virtual_env()
  if env == "" then
    return ""
  end
  return " " .. env
end

require("lualine").setup {
  options = {
    theme = "auto", -- theo colorscheme đang chạy
    globalstatus = true,
    icons_enabled = true,
    component_separators = { left = "", right = "" },
    section_separators = { left = "", right = "" },
    disabled_filetypes = { statusline = { "snacks_dashboard", "alpha", "dashboard" } },
  },
  sections = {
    lualine_a = { "mode" },
    lualine_b = { { "branch", icon = "" }, { "diff" }, { "diagnostics" } },
    lualine_c = {
      { "filename", path = 1, symbols = { modified = "●", readonly = "" } },
    },
    lualine_x = {
      { py_env, icon = "" },
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
