# configuration.nix — BamOS Base Configuration
# File này được tạo bởi BamOS Calamares installer
# Có thể chỉnh sửa thủ công sau khi cài đặt
#
# Cấu trúc:
#   ./configuration.nix        ← File này: hostname, locale, user
#   ./customized.nix           ← Sinh bởi installer (edition + machine type)
#   ./modules/                 ← User modules (thêm theo nhu cầu)
#   ./customConfig/default.nix ← Config cá nhân (không bị ghi đè)
#
# ▶️ Xem thêm:
#   ./README.md                ← Hướng dẫn sử dụng
#   ./customConfig/default.nix ← Thêm cấu hình cá nhân vào đây!
#
{ config, pkgs, lib, ... }:

{
  # ════════════════════════════════════════════════════════
  # Hostname — thay đổi theo tên máy của bạn
  # ════════════════════════════════════════════════════════
  networking.hostName = "bamos";

  # ════════════════════════════════════════════════════════
  # Locale & Keyboard
  # ════════════════════════════════════════════════════════
  i18n.defaultLocale = "en_US.UTF-8";
  console.useXkbConfig = true;
  services.xserver.xkb.layout = "us";

  # ════════════════════════════════════════════════════════
  # User account (mặc định: bamos)
  # ════════════════════════════════════════════════════════
  users.users.bamos = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "render" ];
    initialPassword = "bamos"; # Đổi mật khẩu sau khi đăng nhập!
  };

  # ════════════════════════════════════════════════════════
  # State version (không thay đổi — NixOS tự quản lý)
  # ════════════════════════════════════════════════════════
  system.stateVersion = "26.05";

  # ════════════════════════════════════════════════════════
  # NetworkManager
  # ════════════════════════════════════════════════════════
  networking.networkmanager.enable = true;

  # ════════════════════════════════════════════════════════
  # Auto-upgrade (BamOS update engine)
  # ════════════════════════════════════════════════════════
  bamos.update.autoUpgrade = true;

  # ════════════════════════════════════════════════════════
  # Flatpak + Flathub
  # ════════════════════════════════════════════════════════
  services.flatpak.enable = true;
}
