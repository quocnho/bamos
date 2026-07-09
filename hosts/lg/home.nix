# hosts/lg/home.nix
# Home-manager user configuration for quocnho (LG Gram)
{ pkgs, config, ... }:

{
  # ═══════════════════════════════════════════════════════
  # Home Manager state version (required)
  # ═══════════════════════════════════════════════════════
  home.stateVersion = "26.05";
  # ═══════════════════════════════════════════════════════
  # Git
  # ═══════════════════════════════════════════════════════
  programs.git = {
    enable = true;
    settings = {
      user.name = "quocnho";
      user.email = "quocnho@gmail.com";
      init.defaultBranch = "main";
      pull.rebase = true;
    };
    signing = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILtLHChwq5J5sjJEMBqAKAcqGC+fhRNLsz5Y2KVF8NV8";
      signByDefault = true;
    };
  };

  # ═══════════════════════════════════════════════════════
  # Shell
  # ═══════════════════════════════════════════════════════
  programs.zsh = {
    enable = true;
    oh-my-zsh.enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      nrs = "sudo nixos-rebuild switch --flake /etc/nixos";
      nfu = "sudo nix flake update --flake /etc/nixos";
      bam = "bam";
    };
  };

  # ═══════════════════════════════════════════════════════
  # Development tools
  # ═══════════════════════════════════════════════════════
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.tmux = {
    enable = true;
    shortcut = "a";
    aggressiveResize = true;
    clock24 = true;
  };

  programs.home-manager.enable = true;
}
