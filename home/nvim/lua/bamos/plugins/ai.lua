-- CodeCompanion.nvim — Trợ lý AI hiện đại trong Neovim (DeepSeek API + Antigravity CLI).
-- Hỗ trợ:
--   • DeepSeek API: Tự động dùng key qua $DEEPSEEK_API_KEY
--   • Antigravity CLI (agy): Chạy trực tiếp qua popup terminal (<space>ag) hoặc gửi context buffer (<space>aG)
--   • Chat buffer: <space>aa
--   • Inline code assistant: <space>ai
--   • Action palette: <space>ac
--   • Giải thích / Fix lỗi: <space>ae / <space>af
local ok, codecompanion = pcall(require, "codecompanion")
if not ok then
  return
end

codecompanion.setup({
  adapters = {
    http = {
      deepseek = "deepseek",
    },
  },
  interactions = {
    chat = {
      adapter = "deepseek",
      roles = {
        llm = "DeepSeek AI",
        user = "Bạn",
      },
    },
    inline = {
      adapter = "deepseek",
    },
    cmd = {
      adapter = "deepseek",
    },
  },
  display = {
    chat = {
      window = {
        layout = "vertical",
        width = 0.4,
        border = "rounded",
      },
    },
    action_palette = {
      width = 95,
      height = 16,
      prompt = "Prompt  ",
      provider = "fzf_lua", -- Tận dụng FzfLua có sẵn trong BamOS
    },
  },
})

-- Keymaps
local map = vim.keymap.set
map({ "n", "v" }, "<space>aa", "<cmd>CodeCompanionChat Toggle<CR>", { desc = "AI Chat (Toggle)" })
map({ "n", "v" }, "<space>ai", "<cmd>CodeCompanion<CR>", { desc = "AI Inline Assistant" })
map({ "n", "v" }, "<space>ac", "<cmd>CodeCompanionActions<CR>", { desc = "AI Actions Palette" })
map("v", "<space>ae", "<cmd>CodeCompanion /explain<CR>", { desc = "AI Giải thích code" })
map("v", "<space>af", "<cmd>CodeCompanion /fix<CR>", { desc = "AI Fix lỗi code" })

-- ================= Google Antigravity CLI (`agy`) Integration =================
-- 1. Mở tương tác toàn diện Antigravity CLI trong popup Snacks terminal
map("n", "<space>ag", function()
  local Snacks = require("snacks")
  if Snacks and Snacks.terminal then
    Snacks.terminal.open("agy", {
      win = {
        position = "float",
        border = "rounded",
        width = 0.9,
        height = 0.9,
      },
    })
  else
    vim.cmd("split | terminal agy")
  end
end, { desc = "Antigravity CLI (agy TUI popup)" })

-- 2. Mở Antigravity CLI đính kèm file hiện tại đang mở
map("n", "<space>aG", function()
  local current_file = vim.fn.expand("%:p")
  local cmd = "agy"
  if current_file ~= "" then
    cmd = string.format("agy --prompt-interactive 'Xem xét file %s: '", current_file)
  end
  local Snacks = require("snacks")
  if Snacks and Snacks.terminal then
    Snacks.terminal.open(cmd, {
      win = {
        position = "float",
        border = "rounded",
        width = 0.9,
        height = 0.9,
      },
    })
  else
    vim.cmd("split | terminal " .. cmd)
  end
end, { desc = "Antigravity CLI (đính kèm file hiện tại)" })
