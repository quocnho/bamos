# Description: Cấu hình Shell (Zsh, Starship prompt, Fzf tìm kiếm mờ, Zoxide chuyển thư mục)
{ ... }:

{
  # ZSH
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;

    history = {
      size = 10000;
      save = 10000;
      ignoreAllDups = true;
      share = true;
    };

    shellAliases = {
      # eza
      ls = "eza --icons --group-directories-first";
      ll = "eza -lh --icons --git --group-directories-first";
      la = "eza -lah --icons --git --group-directories-first";
      lt = "eza --tree --icons --level=2";

      # Git
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

      # Others
      grep = "grep --color=auto";
      zi = "zoxide query -i";

      # Antigravity IDE
      antigravity = "antigravity-ide";
      agy = "agy";

      # NixOS rebuild & flake shortcuts (Bam CLI)
      sw = "bam switch";
      swu = "bam switch -u";
      bt = "bam boot";
      bu = "bam build";
      dry = "bam dry";
      fu = "bam lock";
      chk = "nix flake check /etc/nixos";
      ngc = "bam gc";
    };

    initContent = ''
      setopt autocd
      setopt no_beep
      bindkey '^[[1;5C' forward-word
      bindkey '^[[1;5D' backward-word
    '';
  };

  # Starship prompt
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$python$container$cmd_duration$jobs\n$character";

      directory = {
        truncation_length = 3;
        truncation_symbol = "…/";
        style = "bold cyan";
      };

      git_branch.style = "bold purple";
      git_status.style = "bold red";

      cmd_duration = {
        min_time = 1000;
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

  # FZF
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

  # Zoxide
  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };
}
