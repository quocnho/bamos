# Description: Symlinks cấu hình Neovim Lua sang ~/.config/nvim
{ ... }:

let
  files = [
    # Core
    "lua/bamos/init.lua"
    "lua/bamos/utils.lua"
    "lua/bamos/globals.lua"
    "lua/bamos/options.lua"
    "lua/bamos/autocmds.lua"
    "lua/bamos/ime.lua"
    "lua/bamos/keymaps.lua"
    "lua/bamos/emacs.lua"
    "lua/bamos/diagnostic.lua"
    "lua/bamos/lsp.lua"
    "lua/bamos/theme.lua"
    # Plugins
    "lua/bamos/plugins/icons.lua"
    "lua/bamos/plugins/which-key.lua"
    "lua/bamos/plugins/bufferline.lua"
    "lua/bamos/plugins/lualine.lua"
    "lua/bamos/plugins/snacks.lua"
    "lua/bamos/plugins/cmp.lua"
    "lua/bamos/plugins/treesitter.lua"
    "lua/bamos/plugins/picker.lua"
    "lua/bamos/plugins/explorer.lua"
    "lua/bamos/plugins/git.lua"
    "lua/bamos/plugins/editor.lua"
    "lua/bamos/plugins/folding.lua"
    "lua/bamos/plugins/statuscol.lua"
    "lua/bamos/plugins/navigation.lua"
    "lua/bamos/plugins/markdown.lua"
    "lua/bamos/plugins/terminal.lua"
    "lua/bamos/plugins/notes.lua"
    "lua/bamos/plugins/todo.lua"
    "lua/bamos/plugins/extras.lua"
    "lua/bamos/plugins/ai.lua"
    # LSP per-server
    "after/lsp/lua_ls.lua"
    "after/lsp/pyright.lua"
    "after/lsp/ruff.lua"
    "after/lsp/nil_ls.lua"
    "after/lsp/gopls.lua"
    "after/lsp/clangd.lua"
    "after/lsp/ts_ls.lua"
    "after/lsp/bashls.lua"
    "after/lsp/marksman.lua"
    "after/lsp/yamlls.lua"
    "after/lsp/intelephense.lua"
    "after/lsp/sqls.lua"
    # Filetypes
    "after/ftplugin/python.lua"
    "after/ftplugin/markdown.lua"
    "after/ftplugin/lua.lua"
    "after/ftplugin/go.lua"
    "after/ftplugin/json.lua"
    "after/ftplugin/yaml.vim"
    "after/ftplugin/vim.vim"
    "after/ftplugin/tex.lua"
    "after/ftplugin/help.lua"
    "after/ftplugin/man.lua"
    "after/ftplugin/text.vim"
    "after/ftplugin/qf.vim"
  ];
in
{
  home.file = builtins.listToAttrs (
    map (f: {
      name = ".config/nvim/${f}";
      value = {
        source = ../../nvim/${f};
      };
    }) files
  );
}
