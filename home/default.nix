# Home-manager — cấu hình NGƯỜI DÙNG dùng chung (MỌI máy BamOS: lg + máy cài từ ISO).
#
# Khác với modules/ (cấp hệ thống), home/ quản lý cấu hình trong $HOME của user:
# shell (zsh/starship/fzf/zoxide), git, ssh, gói cài riêng... File này được xuất
# qua `bamos.homeModules.default` để flake máy đích (iso-cfg/flake.nix) dùng chung.
#
# Tham khảo kiến trúc craftzdog/dotfiles (NixOS + home-manager): mỗi "nhóm"
# là một programs.* declarative — không viết dotfile tay, không cần plugin manager.
#
# LƯU Ý:
#   - home.username / home.homeDirectory TỰ SUY từ users.users.<tên> (NixOS module
#     của home-manager) → KHÔNG khai báo ở đây.
#   - KHÔNG hardcode thông tin cá nhân (git user.name/email...) trong file dùng
#     chung — đặt ở home/lg.nix (máy dev) hoặc customConfig/home.nix (máy đích).
#   - Công cụ DEVELOPER (nvim, tmux, gh, direnv...) nằm ở home/dev.nix
#     (bamos.homeModules.dev) — bật riêng, tránh nặng cho người dùng cuối.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Bắt buộc — phiên bản trạng thái (khớp system.stateVersion của NixOS).
  home.stateVersion = "25.11";

  # ==========================================================================
  #  SHELL — zsh + starship + fzf + zoxide (chuyển từ modules/shell.nix lên đây)
  # ==========================================================================
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true; # gợi ý lệnh khi gõ
    syntaxHighlighting.enable = true; # tô màu cú pháp
    enableCompletion = true; # hoàn thành lệnh (compinit)

    history = {
      size = 10000;
      save = 10000;
      ignoreAllDups = true; # không lưu lệnh trùng
      share = true; # chia sẻ giữa các terminal
    };

    shellAliases = {
      # Hiển thị đẹp với eza (cài trong modules/packages.nix)
      ls = "eza --icons --group-directories-first";
      ll = "eza -lh --icons --git --group-directories-first";
      la = "eza -lah --icons --git --group-directories-first";
      lt = "eza --tree --icons --level=2";

      # Git nhanh
      g = "git";
      ga = "git add";
      gcm = "git commit -m";
      gco = "git checkout";
      gb = "git branch";
      gs = "git status";
      gd = "git diff";
      gl = "git log --oneline --graph --decorate -20";
      gp = "git push";
      gpl = "git pull";
      gac = "git add -A && git commit -m \"Update\"";

      # Khác
      grep = "grep --color=auto";
      zi = "zoxide query -i"; # chọn thư mục bằng fzf

      # Antigravity IDE (binary là antigravity-ide) + CLI (agy)
      antigravity = "antigravity-ide";
      agy = "agy";

      # ==== NixOS rebuild & flake shortcuts (Bam CLI — `bam help`) ====
      # bam tự dò host (lg/bamos) + tự gắn tag "BamOS-YY.MM.DD-HH:MM" khi
      # switch/boot (system.nixos.tags đọc BAMOS_TAG qua --impure — profiles/common.nix).
      sw = "bam switch";
      swu = "bam switch -u"; # kèm nix flake update trước
      bt = "bam boot";
      bu = "bam build";
      dry = "bam dry";
      fu = "bam lock";
      chk = "nix flake check /etc/nixos";
      ngc = "bam gc";

      # ==== Điều phối Monorepo (Troly C++20 / Qt6) ====
      troly-build = "devenv shell troly-build";
      troly-run = "devenv shell troly-run";
      troly-preview = "devenv shell troly-preview";
      tb = "devenv shell troly-build";
      tr = "devenv shell troly-run";
      tp = "devenv shell troly-preview";

      # ==== Điều phối Monorepo (Assistant Go / GTK) ====
      assistant-build = "devenv shell assistant-build";
      assistant-run = "devenv shell assistant-run";
      ab = "devenv shell assistant-build";
      ar = "devenv shell assistant-run";

      # ==== Điều phối Monorepo (BamOS Distro) ====
      distro-dry = "devenv shell distro-dry";
      distro-build = "devenv shell distro-build";
      distro-iso = "devenv shell distro-iso";
      dd = "devenv shell distro-dry";
      db = "devenv shell distro-build";
      di = "devenv shell distro-iso";
    };

    initContent = ''
      # ==== Tiện ích ====
      setopt autocd           # gõ tên thư mục là cd vào ngay
      setopt no_beep

      # ==== Phím tắt: di chuyển theo từ với Ctrl+←/→ ====
      bindkey '^[[1;5C' forward-word
      bindkey '^[[1;5D' backward-word
    '';
  };

  # Starship: prompt 2 dòng đẹp mắt (tự thêm `eval "$(starship init zsh)"` vào .zshrc)
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;

      # Dòng 1 = ngữ cảnh (thư mục, git, python, container, thời gian)
      # Dòng 2 = nơi nhập lệnh
      format = "$directory$git_branch$git_status$python$container$cmd_duration$jobs\n$character";

      directory = {
        truncation_length = 3; # giữ 3 cấp thư mục cuối
        truncation_symbol = "…/";
        style = "bold cyan";
      };

      git_branch = {
        style = "bold purple";
      };
      git_status = {
        style = "bold red";
      };

      cmd_duration = {
        min_time = 1000; # chỉ hiện khi lệnh chạy > 1s
        show_milliseconds = true;
        format = "took [$duration]($style) ";
        style = "yellow";
      };

      jobs = {
        threshold = 1;
        style = "blue";
      };

      container = {
        symbol = "";
        format = "[$symbol]($style) ";
        style = "bright-magenta";
      };

      python = {
        format = "[$symbol$version]($style) ";
        style = "green";
      };

      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
      };
    };
  };

  # FZF: tìm kiếm mờ — Ctrl+T: file • Ctrl+R: lịch sử • Alt+C: đổi thư mục
  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    defaultOptions = [
      "--height 60%"
      "--border"
      "--preview 'bat --color=always --style=numbers --line-range=:300 {}'"
    ];
    changeDirWidget = {
      command = "fd --type d --hidden --follow --exclude .git";
    };
  };

  # Zoxide: điều hướng thư mục thông minh — gõ `z proj` là nhảy tới ngay
  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

  # ==========================================================================
  #  GIT — user-level ~/.gitconfig (bổ sung /etc/gitconfig cấp hệ thống)
  # ==========================================================================
  # Định danh user.name/user.email KHÔNG đặt ở đây (file dùng chung) — đặt ở
  # home/lg.nix (máy dev) hoặc customConfig/home.nix (máy cài từ ISO).
  programs.git = {
    enable = true;

    settings = {
      alias = {
        st = "status";
        co = "checkout";
        br = "branch -a";
        ci = "commit";
        lg = "log --oneline --graph --decorate -20";
        pl = "pull --rebase";
      };
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true; # `git push` lần đầu tự tạo remote branch
      merge.conflictstyle = "zdiff3";
      diff.algorithm = "histogram";
    };
  };

  # Diff pager đẹp (delta) — tự gắn [pager] diff = delta vào git config
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      line-numbers = true;
      navigate = true;
      syntax-theme = "GitHub";
    };
  };

  # ==========================================================================
  #  SSH — ~/.ssh/config (quản lý declarative)
  # ==========================================================================
  # Thêm host riêng qua matchBlocks (xem example đã comment bên dưới).
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false; # không dùng defaults cũ — tự khai báo qua settings
    settings = {
      "*" = {
        AddKeysToAgent = "yes"; # thêm key vào agent khi dùng
        ServerAliveInterval = 60; # giữ kết nối khi không gõ phím
      };
    };
    matchBlocks = { };
    # matchBlocks = {
    #   "github.com" = {
    #     hostname = "github.com";
    #     user = "git";
    #     identityFile = "~/.ssh/id_ed25519";
    #   };
    # };
  };

  # ==========================================================================
  #  GÓI CÀI RIÊNG CHO USER (vào ~/.nix-profile — bổ sung systemPackages)
  # ==========================================================================
  home.packages = with pkgs; [
    jq # xử lý JSON
    yq # xử lý YAML
    ripgrep # tìm kiếm nhanh (backend fzf/zed)
    tree # xem cây thư mục
    tldr # man ngắn gọn (tealdeer)
    duf # dung lượng ổ đĩa đẹp mắt
    ncdu # dọn ổ đĩa tương tác
    btop # theo dõi CPU/RAM hiện đại (htop có sẵn cấp hệ thống)
  ];
}
