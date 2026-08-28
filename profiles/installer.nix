# Profile INSTALLER — LiveCD cài bamos cho người dùng khác.
#
# Tham khảo sâu GLF-OS (framagit.org/gaming-linux-fr/glf-os):
#   - GLF-OS dùng Calamares GUI (installation-cd-graphical-calamares-gnome.nix)
#     + module Python tự sinh config + copy flake vào /etc/nixos máy đích.
#   - bamos dùng bản NHẸ hơn: installation-cd-minimal (console) + script
#     dialog TUI (installer/install.sh) đi cùng luồng: partition → mount →
#     nixos-generate-config → ghi flake + configuration.nix → nixos-install
#     --flake <root>/etc/nixos#bamos.
#   - Muốn nâng cấp lên Calamares GUI: đổi module cd-dvd trong flake.nix
#     (host installer) + viết module Calamares theo patches/ của GLF-OS.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # LiveCD cần flakes để chạy nixos-install --flake
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # ==== ISO ====
  isoImage = {
    appendToMenuLabel = " Bamos Installer";
    volumeID = "BAMOS-INSTALL";
    # Nén squashfs tối đa cho ISO (bản dev có thể hạ xuống level 1 cho nhanh)
    squashfsCompression = "zstd -Xcompression-level 12";
    # Nhúng toàn bộ thư mục installer/ vào gốc squashfs → trên LiveCD nằm ở
    # /installer (chứa flake.nix, install.sh — installer đọc từ đây).
    contents = [
      {
        source = ../installer;
        target = "/installer";
      }
    ];
    storeContents = [ config.system.build.toplevel ];
  };

  # ==== Công cụ installer ====
  environment.systemPackages = with pkgs; [
    dialog # giao diện TUI
    parted # phân vùng GPT
    btrfs-progs # hỗ trợ Btrfs nếu cần
    (pkgs.writeShellScriptBin "bamos-install" ''
      exec bash /installer/install.sh
    '')
  ];

  # ==== Tự đăng nhập root trên tty1 → chạy installer ngay ====
  services.getty.autologinUser = "root";

  # Banner console hướng dẫn (hiện khi autologin)
  environment.etc."issue" = {
    text = ''
      ╔══════════════════════════════════════════════════════════╗
      ║            BAMOS NIXOS INSTALLER                         ║
      ║  Chạy lệnh:  bamos-install                               ║
      ║  (chia ổ, sinh cấu hình, cài NixOS + flake kéo config    ║
      ║   từ github.com/quocnho/bamos)                           ║
      ╚══════════════════════════════════════════════════════════╝
    '';
  };
}
