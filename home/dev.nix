# Home-manager dành cho DEVELOPER — Neovim + tmux + gh + direnv + dev CLIs.
#
# Bật:
#   - Máy dev (lg):   home/lg.nix import ./dev.nix (mặc định)
#   - Máy đích (ISO): bỏ comment `imports = [ bamos.homeModules.dev ]` trong
#                     /etc/nixos/customConfig/home.nix
#
# NEOVIM — kiến trúc hiện đại, tham khảo ray-x/nvim + LazyVim (look
# jellydn/lazy-nvim-ide, appelgriebsch/Nv):
#   • Cấu trúc domain rõ ràng: lua/bamos/ = core (options, keymaps, autocmds,
#     lsp, theme) + lua/bamos/plugins/* = MỘT FILE MỘT PLUGIN (như LazyVim).
#   • after/lsp/* = cấu hình riêng từng LSP server; after/ftplugin/* = theo filetype.
#   • Nhẹ (tinh thần ray-x): plugin tinh gọn, tận dụng native Neovim 0.12 —
#     vim.lsp.enable(), treesitter, pack native, snacks (1 plugin thay nhiều).
#   • Look LazyVim: snacks.dashboard (home screen khi `nvim` không file) +
#     bufferline (tab) + which-key v3 (menu phím) + theme TokyoNight mặc định.
#
# ĐIỀU CHỈNH CHO NIXOS + DEVENV:
#   • Plugins cài qua Nix (vimPlugins — pack native của home-manager) → KHÔNG
#     cần lazy.nvim: offline, reproducible, "cài mới là chạy".
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

let
  # Plugin jellydn chưa có trong nixpkgs → pin trực tiếp GitHub (reproducible:
  # cố định rev + sha256, không phụ thuộc trạng thái remote lúc rebuild).
  # Muốn nâng cấp: đổi rev + chạy `nix-prefetch-url --unpack <archive-url>` lấy hash mới.
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
  # ==========================================================================
  #  NEOVIM — kiến trúc lua/bamos (xem comment đầu file)
  # ==========================================================================
  programs.neovim = {
    enable = true;
    defaultEditor = true; # EDITOR/VISUAL = nvim
    viAlias = true;
    vimAlias = true;
    withPython3 = false; # không dùng provider python (plugin đều là Lua)
    withRuby = false;

    plugins = with pkgs.vimPlugins; [
      # ---- LSP & completion ----
      nvim-lspconfig # registry config cho vim.lsp.enable (Neovim ≥ 0.11)
      blink-cmp # completion engine (nhanh, gọn — thay nvim-cmp)
      friendly-snippets # bộ snippets sẵn (vscode format)
      luasnip # snippet engine cho blink.cmp
      plenary-nvim # thư viện dùng chung

      # ---- Cú pháp & text objects ----
      nvim-treesitter.withAllGrammars # grammar cài qua Nix (không tải lúc chạy)
      # Bỏ dep nvim-treesitter bản thường (tránh "two different versions")
      (nvim-treesitter-textobjects.overrideAttrs (o: {
        passthru = (o.passthru or { }) // {
          dependencies = [ ];
        };
      }))
      targets-vim # text objects nâng cao (a/ i/ theo dấu câu & ngoặc)

      # ---- Tìm kiếm & điều hướng ----
      fzf-lua # fuzzy finder chính (nhẹ — ray-x cũng dùng)
      hop-nvim # nhảy nhanh (EasyMotion-style)
      nvim-hlslens # hiện số match khi tìm kiếm
      aerial-nvim # outline symbol (sidebar phải)

      # ---- Editor helpers ----
      nvim-autopairs # tự đóng ngoặc
      vim-sandwich # bọc/xoá cặp: cs/ds/ys
      vim-commentary # comment: gc
      vim-repeat # lặp plugin map bằng "."
      yanky-nvim # lịch sử yank
      vim-eunuch # :Rename, :Delete, :SudoWrite…
      vim-matchup # match ngoặc thông minh (thay matchparen)
      vim-oscyank # copy ra ngoài qua OSC52 (tmux/ssh)

      # ---- Git ----
      vim-fugitive
      gitsigns-nvim

      # ---- UI (look LazyVim) ----
      lualine-nvim # statusline
      bufferline-nvim # thanh tab kiểu IDE
      which-key-nvim # menu phím tắt (v3)
      snacks-nvim # dashboard + notifier + indent + bigfile + lazygit…
      nvim-colorizer-lua # hiện màu hex/css
      render-markdown-nvim # render markdown trong buffer
      statuscol-nvim # cột số/sign gọn (click được)
      nvim-ufo # fold thông minh (LSP/treesitter)
      promise-async # dependency của nvim-ufo
      oil-nvim # file explorer (sửa filesystem như buffer — LazyVim/tiny-nvim style)
      # nvim-tree-lua # nếu thích sidebar kiểu cũ (xem lua/bamos/plugins/explorer.lua)
      mini-icons # icon file (mock nvim-web-devicons — nhẹ hơn)
      fidget-nvim # tiến trình LSP
      nvim-lightbulb # gợi ý code action
      nvim-bqf # quickfix đẹp
      vim-illuminate # highlight từ cùng tên
      todo-comments-nvim # highlight + tìm TODO/FIXME (hỗ trợ developer)

      # ---- Plugin jellydn (chưa có trong nixpkgs — pin rev/hash ở đầu file) ----
      nui-nvim # UI component library (dependency của my-note)
      jellydnPlugins.my-note-nvim # ghi chú nhanh trong cửa sổ nổi (`,n`)
      jellydnPlugins.tiny-term-nvim # terminal toggle float/split — 0 dependency

      # ---- Colorschemes (mặc định tokyonight — đổi bằng `,ut` / :BamosTheme) ----
      tokyonight-nvim
      catppuccin-nvim
      gruvbox-material
      nightfox-nvim
      kanagawa-nvim
      # thêm theme: thêm plugin ở đây + thêm entry trong lua/bamos/theme.lua

      # ---- BỘ MỞ RỘNG — bỏ comment khi cần (thêm file setup trong
      # ---- lua/bamos/plugins/ nếu plugin cần cấu hình) ----
      # diffview-nvim          # UI diff/log (thay bằng lazygit <space>gg)
      # glance-nvim            # peek definition/references
      # gitlinker-nvim         # copy link github
      # dropbar-nvim           # breadcrumb winbar
      # nvim-tree-lua          # sidebar explorer (thay oil — xem explorer.lua)
      # flash-nvim             # nhảy/tìm nhanh (thay hop — cần đổi keymap do xung đột s)
    ];

    # Entry: nạp lua/bamos/* (cấu trúc mới — xem lua/bamos/init.lua)
    initLua = ''
      require("bamos")
    '';

    # Công cụ cho nvim (LSP server + formatter + tìm kiếm) — có trong PATH của nvim.
    # Server nào DEVENV cung cấp thì tự động có (không cần khai báo ở đây).
    extraPackages = with pkgs; [
      # ---- LSP servers (bộ mặc định BamOS — khớp lua/bamos/lsp.lua) ----
      nil # Nix
      lua-language-server # Lua
      pyright # Python
      typescript-language-server # TS/JS
      bash-language-server # Bash
      marksman # Markdown
      yaml-language-server # YAML
      vscode-langservers-extracted # HTML/CSS/JSON
      taplo # TOML

      # ---- Lint/format Python ----
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

  # Lua/Vim config của nvim → ~/.config/nvim/ (lua/bamos/ = core + plugins theo
  # plugin, after/lsp/ = cấu hình từng LSP server, after/ftplugin/ = theo
  # filetype). init.lua do home-manager sinh (initLua ở trên).
  home.file = builtins.listToAttrs (
    map
      (f: {
        name = ".config/nvim/${f}";
        value = {
          source = ./nvim/${f};
        };
      })
      [
        # ---- Core (lua/bamos) ----
        "lua/bamos/init.lua"
        "lua/bamos/utils.lua"
        "lua/bamos/globals.lua"
        "lua/bamos/options.lua"
        "lua/bamos/autocmds.lua"
        "lua/bamos/ime.lua"
        "lua/bamos/keymaps.lua"
        "lua/bamos/diagnostic.lua"
        "lua/bamos/lsp.lua"
        "lua/bamos/theme.lua"
        # ---- Plugins (lua/bamos/plugins) — một file một plugin ----
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
  #  ZED — cấu hình (settings/keymap/skills) qua home-manager
  # ==========================================================================
  # User service chạy mỗi lần đăng nhập (đồng bộ từ assets/zed sang ~/.config/zed):
  #   1. MERGE settings.json → ~/.config/zed/settings.json (KHÔNG đè block "agent"
  #      — quyền tool đã duyệt vẫn giữ) + thay __HOME__ (context server fs)
  #   2. Ghi đè keymap.json (cùng prefix <space> với nvim — xem assets/zed/README.md)
  #   3. Copy đè skills/ (assets là nguồn chuẩn)
  # Sửa config ở assets/zed/ (không sửa tay trong ~/.config/zed).
  systemd.user.services.zed-settings = {
    Unit = {
      Description = "Zed: đồng bộ settings/keymap/skills từ assets/zed";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.python3}/bin/python3 ${../assets/zed/sync.py} ${../assets/zed}";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

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
