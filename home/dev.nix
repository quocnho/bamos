# Home-manager dành cho DEVELOPER — Neovim + tmux + gh + direnv + dev CLIs.
#
# Bật:
#   - Máy dev (lg):   home/lg.nix import ./dev.nix (mặc định)
#   - Máy đích (ISO): bỏ comment `imports = [ bamos.homeModules.dev ]` trong
#                     /etc/nixos/customConfig/home.nix
#
# NEOVIM theo CHUẨN jdhao/nvim-config (https://github.com/jdhao/nvim-config):
#   • Cùng kiến trúc: lua/user/{globals,options,autocmd,mappings,utils,lsp,diagnostic,ui}
#     + lua/user/plugins/* (như lua/config/*) + after/lsp/* + after/ftplugin/*.
#   • Cùng bộ plugin: blink.cmp, fzf-lua, treesitter-textobjects, hop, hlslens,
#     glance, yanky, iswap, statuscol, nvim-ufo, aerial, nvim-tree, diffview,
#     gitlinker, snacks, mini.icons, colorful-menu...
#   • Cùng cách LSP: server cài NGOÀI (Nix/devenv) + `vim.lsp.enable()` tự dò PATH.
#
# ĐIỀU CHỈNH CHO NIXOS + DEVENV:
#   • Plugins cài qua Nix (vimPlugins) → không cần lazy.nvim, offline, reproducible.
#   • LSP server mặc định cài qua extraPackages; server của dự án (devenv.nix)
#     tự xuất hiện trong PATH khi `direnv allow` → nvim tự bật, không sửa config.
#   • Grammar treesitter cài qua nixpkgs (withAllGrammars) → không cần compiler.
#
# Nguyên tắc: plugin hay dùng thì BẬT; ít dùng để COMMENT — bỏ # là dùng.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # ==========================================================================
  #  NEOVIM — theo chuẩn jdhao/nvim-config
  # ==========================================================================
  programs.neovim = {
    enable = true;
    defaultEditor = true; # EDITOR/VISUAL = nvim
    viAlias = true;
    vimAlias = true;
    withPython3 = false; # không dùng provider python (plugin đều là Lua)
    withRuby = false;

    plugins = with pkgs.vimPlugins; [
      # ---- LSP & completion (blink.cmp — mặc định của jdhao) ----
      nvim-lspconfig
      blink-cmp
      blink-compat
      friendly-snippets # bộ snippets sẵn (vscode format)
      luasnip # snippet engine cho blink.cmp
      plenary-nvim

      # ---- Cú pháp & text objects ----
      nvim-treesitter.withAllGrammars # grammar cài qua Nix (không tải lúc chạy)
      nvim-treesitter-textobjects
      targets-vim # text objects nâng cao (a/ i/ kèm nhiều dấu)

      # ---- Tìm kiếm & điều hướng ----
      fzf-lua # fuzzy finder chính (thay telescope — như jdhao)
      hop-nvim # nhảy nhanh (EasyMotion-style)
      nvim-hlslens # hiện số match khi tìm kiếm
      glance-nvim # peek definition/references
      aerial-nvim # outline symbol

      # ---- Editor helpers ----
      nvim-autopairs
      vim-sandwich # bọc/xoá cặp: cs/ds/ys
      vim-commentary # comment: gc
      vim-repeat
      iswap-nvim # đổi chỗ tham số
      yanky-nvim # lịch sử yank
      vim-eunuch # :Rename, :Delete, :SudoWrite...
      vim-matchup # match ngoặc thông minh (thay matchparen)
      unicode-vim # ga: thông tin ký tự unicode
      asyncrun-vim # :AsyncRun chạy lệnh bất đồng bộ
      vim-scriptease # công cụ cho người viết vim plugin
      vim-toml # syntax toml
      vim-oscyank # copy ra ngoài qua OSC52 (tmux/ssh)

      # ---- Git ----
      vim-fugitive
      gitsigns-nvim
      diffview-nvim # UI diff/log đẹp
      gitlinker-nvim # copy link github/gitlab

      # ---- UI ----
      lualine-nvim
      bufferline-nvim
      which-key-nvim
      nvim-notify
      snacks-nvim # bộ tiện ích (indent, bigfile, notifier...)
      nvim-colorizer-lua # hiện màu hex/css
      render-markdown-nvim # render markdown trong buffer
      colorful-menu-nvim # menu completion màu theo kind
      dropbar-nvim # breadcrumb theo cú pháp
      statuscol-nvim # cột số/sign gọn
      nvim-ufo # fold thông minh (LSP/treesitter)
      promise-async # dependency của nvim-ufo
      nvim-tree-lua # file explorer
      mini-icons # icon file (mock nvim-web-devicons)
      mini-indentscope # vạch indent theo scope
      fidget-nvim # tiến trình LSP
      nvim-lightbulb # gợi ý code action
      quicker-nvim # quickfix đẹp
      nvim-bqf # quickfix buffer
      vim-illuminate # highlight từ cùng tên
      whitespace-nvim # hiện khoảng trắng thừa

      # ---- Colorschemes (chuẩn jdhao: chọn ngẫu nhiên mỗi lần mở) ----
      tokyonight-nvim
      catppuccin-nvim
      gruvbox-material
      everforest
      nightfox-nvim
      kanagawa-nvim
      onedark-nvim
      # thêm theme: vd oxocarbon-nvim + thêm entry trong lua/user/ui.lua
    ];

    # Entry: nạp lua/user/* (cấu trúc theo jdhao — xem bên dưới)
    initLua = ''
      require("user")
    '';

    # Công cụ cho nvim (LSP server + formatter + tìm kiếm) — có trong PATH của nvim.
    # Server nào DEVENV cung cấp thì tự động có (không cần khai báo ở đây).
    extraPackages = with pkgs; [
      # ---- LSP servers (bộ mặc định BamOS — khớp lua/user/lsp.lua) ----
      nil # Nix
      lua-language-server # Lua
      pyright # Python
      typescript-language-server # TS/JS
      bash-language-server # Bash
      marksman # Markdown
      yaml-language-server # YAML
      vscode-langservers-extracted # HTML/CSS/JSON
      taplo # TOML

      # ---- Lint/format Python (chuẩn jdhao: black + ruff) ----
      black
      ruff

      # ---- Formatter khác (dùng trong after/ftplugin) ----
      stylua # Lua
      nixfmt # Nix (nil_ls cũng gọi nixfmt để format)

      # ---- Fuzzy finder backend (fzf-lua) ----
      fzf
      fd
      ripgrep
      bat

      # ---- BỘ MỞ RỘNG — bỏ comment khi cần (LSP tự bật qua PATH detection) ----
      # gopls                  # Go (thêm dòng "gopls" nếu muốn bắt buộc — lsp.lua đã có optional)
      # rust-analyzer          # Rust
      # clang-tools            # C/C++ (clangd)
      # jdt-language-server    # Java (jdtls)
      # typos-lsp              # soát lỗi chính tả
      # shfmt                  # Shell format
      # prettierd              # JS/TS/CSS/HTML/JSON format
      # dockerfile-language-server-nodejs # Dockerfile
      # terraform-ls           # Terraform
    ];
  };

  # Lua/Vim config của nvim → ~/.config/nvim/ (cấu trúc theo chuẩn jdhao:
  # lua/user/ = core + plugins, after/lsp/ = cấu hình từng LSP server,
  # after/ftplugin/ = cấu hình theo filetype). init.lua do home-manager sinh.
  home.file = builtins.listToAttrs (
    map
      (f: {
        name = ".config/nvim/${f}";
        value = {
          source = ./nvim/${f};
        };
      })
      [
        # ---- Core (lua/user) ----
        "lua/user/init.lua"
        "lua/user/utils.lua"
        "lua/user/globals.lua"
        "lua/user/options.lua"
        "lua/user/autocmd.lua"
        "lua/user/mappings.lua"
        "lua/user/lsp.lua"
        "lua/user/diagnostic.lua"
        "lua/user/ui.lua"
        # ---- Plugins (lua/user/plugins) ----
        "lua/user/plugins/fzf-lua.lua"
        "lua/user/plugins/blink-cmp.lua"
        "lua/user/plugins/treesitter.lua"
        "lua/user/plugins/lualine.lua"
        "lua/user/plugins/bufferline.lua"
        "lua/user/plugins/which-key.lua"
        "lua/user/plugins/git.lua"
        "lua/user/plugins/navigation.lua"
        "lua/user/plugins/explorer.lua"
        "lua/user/plugins/editor.lua"
        "lua/user/plugins/ui.lua"
        # ---- LSP per-server (after/lsp) ----
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
        # ---- Filetype (after/ftplugin) ----
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

  # ==========================================================================
  #  TMUX — session/tab/panel (craftzdog workflow: tmux + editor)
  # ==========================================================================
  programs.tmux = {
    enable = true;
    shortcut = "a"; # prefix C-a
    mouse = true;
    terminal = "tmux-256color";
    historyLimit = 10000;
    escapeTime = 0;

    extraConfig = ''
      set -g renumber-windows on
      set -g @continuum-restore 'on'
      set -g @resurrect-capture-pane-contents 'on'
      bind r source-file ~/.config/tmux/tmux.conf \; display "Reloaded!"
    '';

    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      resurrect
      continuum
    ];
  };

  # ==========================================================================
  #  GIT TOOLS
  # ==========================================================================
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };

  programs.lazygit = {
    enable = true; # UI git tương tác
  };

  # ==========================================================================
  #  DIRENV — nạp env theo thư mục (devenv/nix-direnv). Trước đây ở modules/dev.nix.
  # ==========================================================================
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

  # ==========================================================================
  #  DEV CLIs
  # ==========================================================================
  home.packages = with pkgs; [
    git-lfs
    just
    ghq
    # ---- BỘ MỞ RỘNG — bỏ comment khi cần ----
    # docker-compose
    # httpie
    # kubectl
    # helm
    # terraform
    # awscli2
    # google-cloud-sdk
    # sqlite
    # postgresql
    # redis
  ];
}
