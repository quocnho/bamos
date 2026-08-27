# Git, shell (zsh + starship) và direnv.
{ config, lib, pkgs, ... }:

{
  programs.git = {
    enable = true;
    config = { user.name = "quocnho"; user.email = "quocnho@gmail.com"; };
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$container$character";
      container = { symbol = " "; format = "[$symbol]($style) "; style = "bright-magenta"; };
    };
  };

  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    promptInit = ''
      eval "$(starship init zsh)"
    '';
  };

  programs.direnv = { enable = true; nix-direnv.enable = true; };
}
