# configuration.nix — BamOS Base Configuration
# File này được tạo bởi BamOS Calamares installer
# Có thể chỉnh sửa thủ công sau khi cài đặt
#
# Cấu trúc:
#   ./configuration.nix        ← File này: hostname, locale, user
#   ./customized.nix           ← Sinh bởi installer (edition + machine type)
#   ./customConfig/default.nix  ← Người dùng tự thêm (không bị ghi đè)
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
  # User account
  # ════════════════════════════════════════════════════════
  users.users.bamos = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "render" ];
    initialPassword = "bamos"; # Đổi mật khẩu sau khi đăng nhập!
  };

  # ════════════════════════════════════════════════════════
  # State version (không thay đổi)
  # ════════════════════════════════════════════════════════
  system.stateVersion = "26.05";
}
