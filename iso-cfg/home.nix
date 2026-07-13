# home.nix — Home-Manager User Config (Optional)
# Dùng để quản lý user-level config: dotfiles, shell, editor, git
#
# 📝 Cách kích hoạt:
#   1. Bỏ comment phần home-manager trong flake.nix
#   2. Thêm config vào đây
#   3. sudo nixos-rebuild switch --flake /etc/nixos#bamos
#
{ config, pkgs, lib, ... }:

{
  # ─── Git ───
  programs.git = {
    enable = true;
    userName = "Your Name";
    userEmail = "your@email.com";
  };

  # ─── Shell ───
  programs.zsh = {
    enable = true;
    oh-my-zsh.enable = true;
  };

  # ─── Editor ───
  programs.vscode.enable = true;

  # ─── Packages ───
  home.packages = with pkgs; [
    # Thêm user-level packages ở đây
  ];

  home.stateVersion = "26.05";
}
