# Home-manager — cấu hình NGƯỜI DÙNG dùng chung (MỌI máy BamOS: lg + máy cài từ ISO).
#
# Khác với modules/ (cấp hệ thống), home/ quản lý cấu hình trong $HOME của user:
# gói cài riêng, git config, dotfiles... File này được xuất qua
# `bamos.homeModules.default` để flake máy đích (iso-cfg/flake.nix) dùng chung.
#
# LƯU Ý:
#   - home.username / home.homeDirectory TỰ SUY từ users.users.<tên> (NixOS module
#     của home-manager — xem home-manager nixos/common.nix) → KHÔNG khai báo ở đây.
#   - KHÔNG hardcode thông tin cá nhân (vd git user.name/user.email) trong file
#     dùng chung — đặt ở home/lg.nix (máy dev) hoặc customConfig/home.nix (máy đích).
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Bắt buộc — phiên bản trạng thái (khớp system.stateVersion của NixOS).
  home.stateVersion = "25.11";

  # ==== Gói cài RIÊNG cho user (vào ~/.nix-profile — bổ sung systemPackages) ====
  home.packages = with pkgs; [
    jq # xử lý JSON (đọc output API/CLI)
    ripgrep # tìm kiếm nhanh (backend fzf/zed)
    tree # xem cây thư mục
    tldr # man ngắn gọn
  ];

  # ==== Git (user-level ~/.gitconfig — bổ sung /etc/gitconfig của modules/shell.nix) ====
  # Định danh user.name/user.email KHÔNG đặt ở đây (file dùng chung) — đặt ở
  # home/lg.nix (máy dev) hoặc customConfig/home.nix (máy cài từ ISO).
  programs.git = {
    enable = true;
    settings.alias = {
      st = "status";
      co = "checkout";
      br = "branch -a";
      ci = "commit";
      lg = "log --oneline --graph --decorate -20";
      pl = "pull --rebase";
    };
  };
}
