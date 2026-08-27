# Git, shell (zsh + starship + fzf + zoxide) và direnv — tối ưu cho developer.
{ config, lib, pkgs, ... }:

{
  programs.git = {
    enable = true;
    config = { user.name = "quocnho"; user.email = "quocnho@gmail.com"; };
  };

  # ==== ZSH chuyên nghiệp ====
  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;    # gợi ý lệnh khi gõ
    syntaxHighlighting.enable = true; # tô màu cú pháp
    enableCompletion = true;          # hoàn thành lệnh (compinit)

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
      zi = "zoxide query -i";   # chọn thư mục bằng fzf
    };

    promptInit = ''
      eval "$(starship init zsh)"
    '';

    interactiveShellInit = ''
      # ==== Lịch sử lệnh: lớn, không trùng, chia sẻ giữa các terminal ====
      HISTFILE=$HOME/.zsh_history
      HISTSIZE=10000
      SAVEHIST=10000
      setopt hist_ignore_all_dups hist_find_no_dups inc_append_history share_history

      # ==== Tiện ích ====
      setopt autocd           # gõ tên thư mục là cd vào ngay
      setopt no_beep

      # ==== Phím tắt: di chuyển theo từ với Ctrl+←/→ ====
      bindkey '^[[1;5C' forward-word
      bindkey '^[[1;5D' backward-word
    '';
  };

  # ==== Zoxide: điều hướng thư mục thông minh (học thói quen, tích hợp fzf) ====
  # Gõ `z proj` → nhảy tới thư mục hay dùng nhất khớp "proj"
  programs.zoxide.enable = true;

  # ==== Starship: prompt 2 dòng đẹp mắt kiểu powerlevel10k ====
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;

      # Dòng 1 = ngữ cảnh (thư mục, git, python, container, thời gian)
      # Dòng 2 = nơi nhập lệnh
      format = "$directory$git_branch$git_status$python$container$cmd_duration$jobs\n$character";

      directory = {
        truncation_length = 3;        # giữ 3 cấp thư mục cuối
        truncation_symbol = "…/";
        style = "bold cyan";
      };

      git_branch = { style = "bold purple"; };
      git_status = { style = "bold red"; };

      cmd_duration = {
        min_time = 1000;              # chỉ hiện khi lệnh chạy > 1s
        show_milliseconds = true;
        format = "took [$duration]($style) ";
        style = "yellow";
      };

      jobs = { threshold = 1; style = "blue"; };

      container = { symbol = ""; format = "[$symbol]($style) "; style = "bright-magenta"; };

      python = { format = "[$symbol$version]($style) "; style = "green"; };

      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
      };
    };
  };

  # ==== FZF: tìm kiếm mờ (fd backend + bat preview) ====
  # Ctrl+T: file • Ctrl+R: lịch sử • Alt+C: đổi thư mục
  programs.fzf = {
    fuzzyCompletion = true;
    keybindings = true;
  };

  environment.sessionVariables = {
    FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git";
    FZF_DEFAULT_OPTS = "--height 60% --border --preview 'bat --color=always --style=numbers --line-range=:300 {}'";
    FZF_CTRL_T_COMMAND = "fd --type f --hidden --follow --exclude .git";
    FZF_ALT_C_COMMAND = "fd --type d --hidden --follow --exclude .git";
  };

  programs.direnv = { enable = true; nix-direnv.enable = true; };
}
