# Cấu hình RIÊNG của máy này (được iso-cfg/flake.nix import).
#
# Nơi để các thứ riêng: hostname khác, GPU (nếu Calamares không dò được),
# packages riêng, ... — KHÔNG cần sửa flake.nix.
#
# VÍ DỤ:
#   { config, lib, pkgs, ... }:
#   {
#     networking.hostName = "may-cua-toi";
#     environment.systemPackages = with pkgs; [ vim git ];
#   }
{ config, lib, ... }:

{
}

# (bamos)
