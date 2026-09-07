-- Snacks.nvim — "bộ tiện ích hiện đại" (folke), dùng cho:
--   • dashboard: home screen kiểu LazyVim/Nv (appelgriebsch/Nv)
--   • notifier:  thay nvim-notify (vim.notify đẹp, gọn, 1 plugin đỡ hơn 2)
--   • indent:    vạch indent liền (thay mini.indentscope — gọn hơn)
--   • bigfile, quickfile, scratch, words, lazygit…
local snacks_ok, snacks = pcall(require, "snacks")
if not snacks_ok then
    return
end

snacks.setup {
    bigfile = { enabled = true },
    dashboard = {
        -- Bố cục kiểu LazyVim/Nv: header (logo) → keys → recent files (bấm số mở ngay).
        -- (KHÔNG dùng section "startup" — nó require lazy.nvim để đo thời gian,
        --  máy không có lazy → sẽ lỗi khi mở dashboard.)
        sections = {
            { section = "header",       align = "center", padding = 1 },
            { section = "keys",         gap = 1,          padding = 1 },
            -- File gần đây: mỗi dòng tự gán ký tự (1..n) — gõ ký tự là MỞ file ngay
            { section = "recent_files", limit = 8,        padding = 1 },
        },
        preset = {
            header = [[
 ██████╗  █████╗ ███╗   ███╗ ██████╗ ███████╗
 ██╔══██╗██╔══██╗████╗ ████║██╔═══██╗██╔════╝
 ██████╔╝███████║██╔████╔██║██║   ██║███████╗
 ██╔══██╗██╔══██║██║╚██╔╝██║██║   ██║╚════██║
 ██████╔╝██║  ██║██║ ╚═╝ ██║╚██████╔╝███████║
 ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝ ╚══════╝]],
            -- Phím tắt — `Snacks.dashboard.pick` TỰ dùng fzf-lua khi có (BamOS có sẵn)
            keys = {
                { icon = " ", key = "f", desc = "Find File",    action = ":lua Snacks.dashboard.pick('files')" },
                { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
                { icon = " ", key = "g", desc = "Find Text",    action = ":lua Snacks.dashboard.pick('live_grep')" },
                { icon = " ", key = "b", desc = "Buffers",      action = ":lua Snacks.dashboard.pick('buffers')" },
                { icon = " ", key = "n", desc = "New File",     action = ":ene | startinsert" },
                { icon = " ", key = "c", desc = "Config",       action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
                { icon = " ", key = "q", desc = "Quit",         action = ":qa" },
            },
        },
    },
    indent = { enabled = true, char = "│" },
    notifier = { enabled = true },
    quickfile = { enabled = true },
    scratch = { enabled = true },
    words = { enabled = true },
    statuscolumn = { enabled = false }, -- đã dùng statuscol.nvim riêng
}

-- Snacks notifier thay thế vim.notify (gọn hơn nvim-notify cũ)
vim.notify = function(msg, level, opts)
    return require("snacks.notifier").notify(msg, level, opts)
end

-- Nhóm autocmd dashboard
local dash_group = vim.api.nvim_create_augroup("bamos_dashboard", { clear = true })

-- Mở dashboard khi chạy `nvim` không kèm file (không mở khi headless/CI)
vim.api.nvim_create_autocmd("VimEnter", {
    group = dash_group,
    callback = function()
        local has_args = vim.fn.argc() > 0
        local has_ui = #vim.api.nvim_list_uis() > 0
        if has_args or not has_ui then
            return
        end
        require("snacks").dashboard.open()
    end,
})

-- Mở dashboard khi tạo TAB MỚI không kèm file (giống Nv: dashboard-nvim/alpha
-- tự hiện ở tab mới). Bỏ qua nếu tab mới đang hiện buffer có nội dung.
vim.api.nvim_create_autocmd("TabNewEntered", {
    group = dash_group,
    callback = function()
        local buf = vim.api.nvim_get_current_buf()
        local name = vim.api.nvim_buf_get_name(buf)
        local ft = vim.bo[buf].filetype
        local buftype = vim.bo[buf].buftype
        if name ~= "" or ft ~= "" or buftype ~= "" then
            return
        end
        require("snacks").dashboard.open()
    end,
})

-- Phím tắt tiện ích snacks
local map = vim.keymap.set
map("n", "<space>gg", function()
    snacks.lazygit.open()
end, { desc = "lazygit (UI git)" })
