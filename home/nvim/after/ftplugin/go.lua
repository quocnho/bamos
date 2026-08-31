-- Go: gofmt khi lưu nếu có (chuẩn jdhao)
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4

vim.keymap.set("n", "<space>f", function()
  vim.cmd("silent !gofmt -w %")
  vim.cmd("edit!")
end, { buffer = true, silent = true, desc = "gofmt" })
