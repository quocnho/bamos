# hosts/lg/home.nix
# Home-manager user configuration for quocnho (LG Gram)
{ pkgs, config, ... }:

{
  # ═══════════════════════════════════════════════════════
  # Git
  # ═══════════════════════════════════════════════════════
  programs.git = {
    enable = true;
    userName = "Nguyen Quoc Nho";
    userEmail = "quocnho@gmail.com";
    signing = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILtLHChwq5J5sjJEMBqAKAcqGC+fhRNLsz5Y2KVF8NV8";
      signByDefault = true;
    };
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };

  # ═══════════════════════════════════════════════════════
  # Shell
  # ═══════════════════════════════════════════════════════
  programs.zsh = {
    enable = true;
    ohMyZsh.enable = true;
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
