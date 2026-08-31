-- Colorscheme: ngẫu nhiên từ danh sách (port lua/ui.lua của jdhao).
-- Danh sách rút gọn cho BamOS — muốn thêm theme: cài plugin trong home/dev.nix
-- + thêm hàm vào bảng dưới (giống jdhao).
local M = {}

local use_theme = function(name)
  local ok, err = pcall(vim.cmd.colorscheme, name)
  if not ok then
    vim.notify(string.format("Không tải được colorscheme %s: %s", name, err), vim.log.levels.WARN)
    vim.cmd.colorscheme("default")
  end
end

M.colorscheme_conf = {
  tokyonight = function()
    use_theme("tokyonight")
  end,
  catppuccin = function()
    use_theme("catppuccin")
  end,
  gruvbox_material = function()
    vim.g.gruvbox_material_foreground = "original"
    vim.g.gruvbox_material_background = "hard"
    vim.g.gruvbox_material_enable_italic = 1
    vim.g.gruvbox_material_better_performance = 1
    use_theme("gruvbox-material")
  end,
  everforest = function()
    vim.g.everforest_background = "hard"
    vim.g.everforest_enable_italic = 1
    vim.g.everforest_better_performance = 1
    use_theme("everforest")
  end,
  nightfox = function()
    use_theme("carbonfox")
  end,
  kanagawa = function()
    use_theme("kanagawa-dragon")
  end,
  onedark = function()
    require("onedark").setup { style = "darker" }
    require("onedark").load()
  end,
}

--- Chọn ngẫu nhiên 1 theme khi mở nvim
M.rand_colorscheme = function()
  math.randomseed(os.time()) -- như jdhao (dùng os.time)
  local names = vim.tbl_keys(M.colorscheme_conf)
  local colorscheme = names[math.random(#names)]
  M.colorscheme_conf[colorscheme]()
  return colorscheme
end

-- gọi ngay khi nạp module
M.rand_colorscheme()

return M
