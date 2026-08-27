# Cấu hình riêng cho host "lg" (LG laptop).
# Phần lớn cấu hình nằm trong các module ở ./modules — bật/tắt bằng các
# option `my.<module>.enable` bên dưới (cấu trúc tương tự flake-parts).
{ config, lib, pkgs, ... }:

{
  imports = [ ./modules/default.nix ];

  # ==== Bật/tắt module ====
  my.boot.enable = true;              # Bootloader, Plymouth, kernel params
  my.gpu.enable = true;               # NVIDIA (GTX 1650) + Intel UHD
  my.gpu.intelBusId = "PCI:0:2:0";
  my.gpu.nvidiaBusId = "PCI:2:0:0";
  my.gnome.enable = true;             # GNOME + GDM
  my.power.enable = true;             # Suspend s2idle + TLP + thức dậy bằng bàn phím

  # ==== Cấu hình riêng của host này ====
  networking.hostName = "lg";

  system.nixos.tags = [ "260826-2350-Initial" ];
  system.stateVersion = "25.11";
}
