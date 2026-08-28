# Profile DESKTOP — GNOME + giao diện kiểu macOS (WhiteSur) + fonts + bootloader.
# Kế thừa profile common (modules dùng chung) rồi bật thêm phần "máy bàn/đồ họa".
#
# Máy đích cài từ ISO dùng profile này qua:
#   bamos.profiles.desktop  (xem installer/flake.nix trên máy đích)
#
# LƯU Ý: phần GPU riêng (NVIDIA/AMD...) và nguồn điện (TLP/pin) KHÔNG nằm ở
# đây — mỗi máy khai báo ở hosts/<máy>.nix (vd: hosts/lg.nix bật my.gpu).
{ config, lib, ... }:

{
  imports = [ ./common.nix ];

  # Bootloader (systemd-boot EFI) + Plymouth splash
  my.boot.enable = true;

  # GNOME desktop + extensions (dash-to-dock, arcmenu, blur-my-shell...)
  my.gnome.enable = true;

  # Giao diện kiểu macOS: WhiteSur theme/icons/cursors + dconf
  my.macos.enable = true;

  # Fonts (Inter + Nerd Fonts) + wallpapers cục bộ (offline)
  my.assets.enable = true;
}
