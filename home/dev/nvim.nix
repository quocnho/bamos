# Description: Cấu hình Neovim (plugins, extraPackages, lua links)
# Tham khảo: ray-x/nvim + LazyVim
{ pkgs, ... }:

let
  jellydnPlugins = {
    my-note-nvim = pkgs.vimUtils.buildVimPlugin {
      name = "my-note-nvim";
      src = pkgs.fetchFromGitHub {
        owner = "jellydn";
        repo = "my-note.nvim";
        rev = "bce15c38514df229eb446a6b6bef2fcbb1993e80";
        sha256 = "1dl57hq833aaaxgc4iyn0b77zgrxmhidzj9xdgylnrhah3k7qdx5";
      };
    };
    tiny-term-nvim = pkgs.vimUtils.buildVimPlugin {
      name = "tiny-term-nvim";
      src = pkgs.fetchFromGitHub {
        owner = "jellydn";
        repo = "tiny-term.nvim";
        rev = "51224ee32fe0e88be1d5dd21afa8874ee7568180";
        sha256 = "0j0qn9q9dzzjihk4fg9wkzbrxrjjwx3925h0rxldd1j5f7q95py0";
      };
    };
  };
in
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withPython3 = false;
    withRuby = false;

    plugins = with pkgs.vimPlugins; [
      # LSP & completion
      nvim-lspconfig
      blink-cmp
      friendly-snippets
      luasnip
      plenary-nvim

      # Syntax & text objects
      nvim-treesitter.withAllGrammars
      (nvim-treesitter-textobjects.overrideAttrs (o: {
        passthru = (o.passthru or { }) // {
          dependencies = [ ];
        };
      }))
      targets-vim

      # Navigation & search
      fzf-lua
      hop-nvim
      nvim-hlslens
      aerial-nvim

      # Editor helpers
      nvim-autopairs
      vim-sandwich
      vim-commentary
      vim-repeat
      yanky-nvim
      vim-eunuch
      vim-matchup
      vim-oscyank

      # Git
      vim-fugitive
      gitsigns-nvim

      # UI
      lualine-nvim
      bufferline-nvim
      which-key-nvim
      snacks-nvim
      nvim-colorizer-lua
      render-markdown-nvim
      statuscol-nvim
      nvim-ufo
      promise-async
      oil-nvim
      mini-icons
      fidget-nvim
      nvim-lightbulb
      nvim-bqf
      vim-illuminate
      todo-comments-nvim

      # Jellydn plugins
      nui-nvim
      jellydnPlugins.my-note-nvim
      jellydnPlugins.tiny-term-nvim

      # AI Assistant
      codecompanion-nvim

      # Themes
      tokyonight-nvim
      catppuccin-nvim
      gruvbox-material
      nightfox-nvim
      kanagawa-nvim
    ];

    initLua = ''
      require("bamos")
    '';

    extraPackages = with pkgs; [
      # LSP servers
      nil
      lua-language-server
      pyright
      typescript-language-server
      vue-language-server
      bash-language-server
      marksman
      yaml-language-server
      vscode-langservers-extracted
      taplo
      intelephense
      gopls
      clang-tools
      sqls
      tailwindcss-language-server

      # Formatters & Linters
      black
      ruff
      stylua
      nixfmt
      prettier
      blade-formatter

      # Tools
      fzf
      fd
      ripgrep
      bat
    ];
  };

  # Link Neovim Lua config
  home.file = builtins.listToAttrs (
    map
      (f: {
        name = ".config/nvim/${f}";
        value = {
          source = ../nvim/${f};
        };
      })
      [
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
      ]
  );
}
