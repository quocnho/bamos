-- Mini.icons: icon file/folder/LSP + mock nvim-web-devicons.
-- Nạp ĐẦU TIÊN (trước bufferline/lualine/snacks…) vì các plugin đó gọi
-- require("nvim-web-devicons") ngay lúc load — mini.icons mock sẵn module này
-- nên không cần cài nvim-web-devicons riêng (nhẹ hơn).
require("mini.icons").setup()

pcall(function()
  require("mini.icons").mock_nvim_web_devicons()
  require("mini.icons").tweak_lsp_kind()
end)
