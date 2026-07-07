# hosts/iso/customConfig/default.nix
# GLF-OS pattern: nơi người dùng thêm cấu hình tùy chỉnh cho ISO
# File này KHÔNG bị ghi đè bởi công cụ tự động
# Áp dụng sau khi sửa: rebuild ISO
{ lib
, config
, pkgs
, ...
}:

{
  # ─── Thêm packages cho live environment ───
  environment.systemPackages = [
    # Thêm packages của bạn ở đây
    # pkgs.htop
    # pkgs.neofetch
  ];

  # ─── Cấu hình tùy chỉnh ───
  # services.openssh.enable = true;
  # services.flatpak.enable = true;
}
