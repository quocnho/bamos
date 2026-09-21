-- LSP configuration.
--
-- ĐIỀU CHỈNH CHO NIXOS + DEVENV:
--   • Server cài qua Nix (programs.neovim.extraPackages) → luôn có trong PATH.
--   • Server do devenv shell cung cấp (devenv.nix → direnv allow) → tự có trong PATH.
--   → Dùng `vim.lsp.enable()` + kiểm tra executable: server nào có trong PATH
--     thì tự bật, không cần khai báo danh sách cứng. Config riêng từng server
--     nằm ở after/lsp/<tên>.lua (cơ chế mặc định của Neovim ≥ 0.11).
local utils = require("bamos.utils")

local api = vim.api

-- ====================== Keymaps khi LSP attach ======================
api.nvim_create_autocmd("LspAttach", {
    group = api.nvim_create_augroup("lsp_buf_conf", { clear = true }),
    callback = function(event_context)
        local client = vim.lsp.get_client_by_id(event_context.data.client_id)
        if not client then
            return
        end

        local bufnr = event_context.buf
        local map = function(mode, l, r, opts)
            opts = opts or {}
            opts.silent = true
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
        end

        map("n", "gd", function()
            vim.lsp.buf.definition {
                on_list = function(options)
                    -- lọc definition trùng (vd: `local M.fn = function()`)
                    local unique_defs, seen = {}, {}
                    for _, loc in pairs(options.items) do
                        local key = loc.filename .. loc.lnum
                        if not seen[key] then
                            seen[key] = true
                            table.insert(unique_defs, loc)
                        end
                    end
                    options.items = unique_defs
                    vim.fn.setloclist(0, {}, " ", options)
                    if #options.items > 1 then
                        vim.cmd.lopen()
                    else
                        vim.cmd("silent! lfirst")
                    end
                end,
            }
        end, { desc = "go to definition" })

        map("n", "<C-]>", vim.lsp.buf.definition)
        map("n", "K", function()
            vim.lsp.buf.hover {
                border = "single",
                max_height = 40,
                max_width = 100,
                close_events = { "CursorMoved", "BufLeave", "WinLeave", "LSPDetach" },
            }
        end)
        map("n", "<C-k>", vim.lsp.buf.signature_help)
        map("n", "<space>rn", vim.lsp.buf.rename, { desc = "rename" })
        map("n", "<space>ca", vim.lsp.buf.code_action, { desc = "code action" })
        map("n", "<space>wa", vim.lsp.buf.add_workspace_folder, { desc = "add workspace folder" })
        map("n", "<space>wr", vim.lsp.buf.remove_workspace_folder, { desc = "remove workspace folder" })
        map("n", "<space>wl", function()
            vim.print(vim.lsp.buf.list_workspace_folders())
        end, { desc = "list workspace folders" })

        -- Không cho ruff hiện hover (tránh trùng với pyright)
        if client.name == "ruff" then
            client.server_capabilities.hoverProvider = false
        end
    end,
    nested = true,
    desc = "LSP buffer keymaps",
})

-- ====================== Default config cho mọi LSP ======================
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true
capabilities.textDocument.completion.completionItem.resolveSupport = {
    properties = { "documentation", "detail", "additionalTextEdits" },
}

vim.lsp.config("*", {
    capabilities = capabilities,
    flags = { debounce_text_changes = 500 },
})

-- ====================== Bật server khi có executable trong PATH ======================
-- `exe` = tên binary trong PATH. `optional = false` → cảnh báo nếu thiếu (server
-- mặc định của BamOS, cài qua extraPackages). `optional = true` → bật nếu có
-- (thường do devenv shell cung cấp), không kêu nếu thiếu.
local enabled_lsp_servers = {
    -- ---- Mặc định BamOS (cài qua programs.neovim.extraPackages) ----
    nil_ls = { exe = "nil", optional = false }, -- Nix
    lua_ls = { exe = "lua-language-server", optional = false },
    pyright = { exe = "pyright", optional = false },
    ts_ls = { exe = "typescript-language-server", optional = false },
    vue_ls = { exe = "vue-language-server", optional = false }, -- Vue SFC (Volar)
    bashls = { exe = "bash-language-server", optional = false },
    marksman = { exe = "marksman", optional = false },
    yamlls = { exe = "yaml-language-server", optional = false },
    html = { exe = "vscode-html-language-server", optional = false },
    cssls = { exe = "vscode-css-language-server", optional = false },
    jsonls = { exe = "vscode-json-language-server", optional = false },
    taplo = { exe = "taplo", optional = false },

    -- ---- Thường do DEVENV shell cung cấp (bật tự động khi có) ----
    ruff = { exe = "ruff", optional = true },
    gopls = { exe = "gopls", optional = true },
    clangd = { exe = "clangd", optional = true },
    intelephense = { exe = "intelephense", optional = true },
    phpactor = { exe = "phpactor", optional = true },
    sqls = { exe = "sqls", optional = true },
    typos_lsp = { exe = "typos-lsp", optional = true },
    tailwindcss = { exe = "tailwindcss-language-server", optional = true },
    emmet_language_server = { exe = "emmet-language-server", optional = true },
    -- thêm server: dòng { tên_lsp = { exe = "binary", optional = true } } + file
    -- after/lsp/<tên_lsp>.lua nếu cần cấu hình riêng.
}

for server_name, server_info in pairs(enabled_lsp_servers) do
    if utils.executable(server_info.exe) then
        vim.lsp.enable(server_name)
    elseif not server_info.optional then
        vim.notify(
            string.format(
                "Executable '%s' cho LSP '%s' không tìm thấy! (cài qua home/dev.nix extraPackages hoặc devenv)",
                server_info.exe, server_name),
            vim.log.levels.WARN,
            { title = "BamOS nvim" }
        )
    end
end

-- ====================== Lệnh LSP ======================
vim.api.nvim_create_user_command("LspInfo", "checkhealth vim.lsp", { desc = "LSP info" })
vim.api.nvim_create_user_command("LspLog", function()
    vim.cmd("edit " .. vim.lsp.log.get_filename())
end, { desc = "LSP log" })
vim.api.nvim_create_user_command("LspRestart", "lsp restart", { desc = "restart LSP" })

-- Inlay hints (tắt mặc định, bật bằng :LspInlayHints enable)
vim.g.lsp_inlay_hint_enabled = false
vim.api.nvim_create_user_command("LspInlayHints", function(context)
    vim.g.lsp_inlay_hint_enabled = context.args == "enable"
    vim.lsp.inlay_hint.enable(vim.g.lsp_inlay_hint_enabled)
end, {
    nargs = 1,
    complete = function()
        return { "enable", "disable" }
    end,
    desc = "toggle LSP inlay hints",
})
