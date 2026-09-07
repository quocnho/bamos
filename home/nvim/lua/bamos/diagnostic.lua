-- Diagnostics: gọn, không virtual text (sign + float + statusline là đủ).
local diagnostic = vim.diagnostic
local api = vim.api

diagnostic.config {
  underline = false, -- không gạch chân (sign + float là đủ)
  virtual_text = false,
  virtual_lines = false,
  signs = {
    text = {
      [diagnostic.severity.ERROR] = "🆇",
      [diagnostic.severity.WARN] = "⚠️",
      [diagnostic.severity.INFO] = "ℹ️",
      [diagnostic.severity.HINT] = "",
    },
  },
  severity_sort = true,
  float = {
    source = true,
    header = "Diagnostics:",
    prefix = " ",
    border = "single",
    max_height = 10,
    max_width = 130,
    close_events = { "CursorMoved", "BufLeave", "WinLeave", "InsertEnter" },
  },
}

-- Đưa diagnostic của buffer vào quickfix
local function set_qflist(buf_num, severity)
  local items = diagnostic.toqflist(diagnostic.get(buf_num, { severity = severity }))
  vim.fn.setqflist({}, " ", { title = "Diagnostics", items = items })
  vim.cmd("copen")
end

vim.keymap.set("n", "<space>qw", diagnostic.setqflist, { desc = "window diagnostics → qf" })
vim.keymap.set("n", "<space>qb", function()
  set_qflist(0)
end, { desc = "buffer diagnostics → qf" })

-- Nhảy giữa các diagnostic (chuẩn LazyVim/dev): ]d/[d
-- (không xung đột: ]c/[c = treesitter class, ]h/[h = gitsigns hunk)
vim.keymap.set("n", "]d", function()
  vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "diagnostic kế tiếp" })
vim.keymap.set("n", "[d", function()
  vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "diagnostic trước" })

-- Tự hiện float diagnostic khi đứng yên trên dòng lỗi
api.nvim_create_autocmd("CursorHold", {
  pattern = "*",
  callback = function()
    if #vim.diagnostic.get(0) == 0 then
      return
    end
    if not vim.b.diagnostics_pos then
      vim.b.diagnostics_pos = { nil, nil }
    end
    local cursor_pos = api.nvim_win_get_cursor(0)
    if not vim.deep_equal(cursor_pos, vim.b.diagnostics_pos) then
      diagnostic.open_float {}
    end
    vim.b.diagnostics_pos = cursor_pos
  end,
})
