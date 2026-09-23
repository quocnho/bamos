# Git + zsh — cấp HỆ THỐNG (tối thiểu, cho mọi user kể cả root).
#
# Cấu hình NGƯỜI DÙNG (aliases, starship prompt, fzf, zoxide, git identity,
# lịch sử zsh...) đã chuyển sang home-manager — xem home/default.nix (shell,
# git) và home/lg.nix (git identity). Lý do: tránh cấu hình chồng chéo giữa
# /etc/zshrc (NixOS) và ~/.zshrc (home-manager) — mỗi tầng lo đúng việc của mình.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Git có sẵn cho MỌI user (identity do home-manager quản lý theo từng user).
  # safe.directory cho /etc/nixos để tránh lỗi dubious ownership khi Flake hoặc user thường truy cập.
  programs.git = {
    enable = true;
    config = {
      safe.directory = [
        "/etc/nixos"
        "/etc/nixos/*"
      ];
      init.defaultBranch = "main";
    };
  };

  # Zsh là shell đăng nhập khả dụng (users.users.*.shell = pkgs.zsh).
  # Cấu hình tương tác của user nằm ở ~/.zshrc (home-manager).
  programs.zsh.enable = true;
}
