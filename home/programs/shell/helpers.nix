# Description: CLI search & jump helpers (fzf & zoxide)
{ ... }:

{
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
