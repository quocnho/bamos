-- Autocommands toàn cục.
local api = vim.api
local augroup = api.nvim_create_augroup("bamos", { clear = true })

-- ====================== Format khi lưu (LSP) ======================
-- Chỉ format các filetype có LSP server đang chạy (server từ Nix hoặc devenv).
-- Muốn tắt: xoá filetype khỏi danh sách dưới.
local format_on_save_ft = {
    python = true,
    lua = true,
    nix = true,
    typescript = true,
    javascript = true,
    typescriptreact = true,
    javascriptreact = true,
    go = true,
    rust = true,
    c = true,
    cpp = true,
    json = true,
    yaml = true,
    markdown = true,
    sh = true,
}

api.nvim_create_autocmd("BufWritePre", {
    group = augroup,
    pattern = "*",
    callback = function(args)
        local ft = vim.bo[args.buf].filetype
        if not format_on_save_ft[ft] then
            return
        end
        if vim.lsp.buf_get_clients(args.buf) == nil or vim.lsp.buf_get_clients(args.buf)[1] == nil then
            return
        end
        vim.lsp.buf.format({ bufnr = args.buf, async = true })
    end,
})

-- ====================== Format web bằng prettier (<space>f) ======================
-- prettier cài sẵn (modules/dev.nix) và xử lý được cả .vue/.ts/.css/.html...
-- Dùng MỘT autocmd theo filetype thay vì nhiều after/ftplugin gần giống nhau.
-- (Format-on-save ở trên chỉ chạy khi LSP có hỗ trợ format; .vue/.css/.html không
--  phải lúc nào cũng có, nên đây là thao tác chủ động.)
local prettier_ft = {
    "typescript", "typescriptreact", "javascript", "javascriptreact",
    "vue", "css", "scss", "less", "html", "json", "jsonc", "yaml", "markdown",
}

local function format_with_prettier()
    if vim.fn.executable("prettier") == 0 then
        vim.notify("Không tìm thấy prettier trong PATH", vim.log.levels.WARN, { title = "BamOS nvim" })
        return
    end
    local view = vim.fn.winsaveview()
    local file = api.nvim_buf_get_name(0)
    vim.cmd("silent! %!prettier --stdin-filepath " .. vim.fn.shellescape(file))
    vim.fn.winrestview(view)
end

api.nvim_create_autocmd("FileType", {
    group = augroup,
    pattern = prettier_ft,
    callback = function(args)
        vim.keymap.set("n", "<space>f", format_with_prettier, {
            buffer = args.buf,
            silent = true,
            desc = "format với prettier",
        })
    end,
})

-- ====================== Nhớ vị trí con trỏ khi mở lại file ======================
api.nvim_create_autocmd({ "BufReadPost" }, {
    group = augroup,
    callback = function(args)
        local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
        local lcount = vim.api.nvim_buf_line_count(args.buf)
        if mark[1] > 0 and mark[1] <= lcount then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
    end,
})

-- ====================== Tự cân chỉnh cửa sổ khi resize ======================
api.nvim_create_autocmd("VimResized", {
    group = augroup,
    callback = function()
        vim.cmd("tabdo wincmd =")
    end,
})

-- ====================== Highlight vùng vừa yank ======================
api.nvim_create_autocmd("TextYankPost", {
    group = augroup,
    callback = function()
        vim.hl.on_yank({ timeout = 200 })
    end,
})

-- ====================== Lệnh: xoá khoảng trắng cuối dòng ======================
api.nvim_create_user_command("StripTrailingWhitespace", function()
    local save = vim.fn.winsaveview()
    vim.cmd([[%s/\s\+$//e]])
    vim.fn.winrestview(save)
end, { desc = "Strip trailing whitespace" })
