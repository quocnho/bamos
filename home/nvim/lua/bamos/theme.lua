-- Colorscheme: mặc định TokyoNight (look LazyVim), chuyển đổi bằng
-- `,ut` / `,uT` hoặc `:BamosTheme <tên>`.
--
-- Muốn thêm theme: cài plugin trong home/dev.nix + thêm hàm vào `themes` dưới.
local M = {}

-- Danh sách theme mặc định BamOS (đã cài trong home/dev.nix)
local themes = {
  "tokyonight",
  "catppuccin",
  "gruvbox-material",
  "kanagawa-dragon",
  "carbonfox",
}

M.default_theme = "tokyonight"

-- Cấu hình riêng từng theme trước khi `:colorscheme`
local theme_config = {
  ["gruvbox-material"] = function()
    vim.g.gruvbox_material_foreground = "original"
    vim.g.gruvbox_material_background = "hard"
    vim.g.gruvbox_material_enable_italic = 1
    vim.g.gruvbox_material_better_performance = 1
  end,
  ["catppuccin"] = function()
    vim.g.catppuccin_flavour = "mocha" -- mocha | macchiato | frappe | latte
  end,
  ["carbonfox"] = function()
    -- nightfox họ: carbonfox (bản tối nhất)
  end,
  ["kanagawa-dragon"] = function()
    -- kanagawa họ: dragon
  end,
}

--- Áp theme theo tên; fallback về default nếu lỗi.
--- @param name string
--- @return boolean success
function M.apply(name)
  name = name or M.default_theme
  local conf = theme_config[name]
  if conf then
    pcall(conf)
  end
  local ok, err = pcall(vim.cmd.colorscheme, name)
  if not ok then
    vim.notify(string.format("Không tải được colorscheme %s: %s", name, err), vim.log.levels.WARN)
    pcall(vim.cmd.colorscheme, M.default_theme)
    return false
  end
  vim.g.bamos_theme = name
  return true
end

--- Chuyển theme: `dir = 1` tới, `dir = -1` lùi.
--- @param dir integer
function M.cycle(dir)
  local cur = vim.g.bamos_theme or M.default_theme
  local i = vim.tbl_contains(themes, cur) and vim.fn.index(themes, cur) or 0
  local next_theme = themes[((i + dir) % #themes) + 1]
  M.apply(next_theme)
  vim.notify(string.format("Theme: %s", next_theme), vim.log.levels.INFO, { title = "BamOS nvim" })
end

-- Command: :BamosTheme <tên> (có gợi ý tên theme)
vim.api.nvim_create_user_command("BamosTheme", function(opts)
  M.apply(opts.args)
end, {
  nargs = 1,
  complete = function()
    return themes
  end,
  desc = "set colorscheme (BamOS)",
})

-- Phím tắt: `,ut` theme tới / `,uT` theme lùi (nhóm "u" = UI)
local keymap = vim.keymap
keymap.set("n", "<leader>ut", function()
  M.cycle(1)
end, { desc = "next theme" })
keymap.set("n", "<leader>uT", function()
  M.cycle(-1)
end, { desc = "prev theme" })

-- Áp ngay khi nạp module (init.lua gọi cuối cùng)
M.apply(M.default_theme)

return M
