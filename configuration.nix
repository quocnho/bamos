# Cấu hình riêng cho host "lg" (LG laptop).
# Phần lớn cấu hình nằm trong các module ở ./modules — bật/tắt bằng các
# option `my.<module>.enable` bên dưới (cấu trúc tương tự flake-parts).
{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/default.nix
  ];

  # ==== Bật/tắt module ====
  my.boot.enable = true;              # Bootloader, Plymouth, kernel params
  my.gpu.enable = true;               # NVIDIA (GTX 1650) + Intel UHD
  my.gpu.intelBusId = "PCI:0:2:0";
  my.gpu.nvidiaBusId = "PCI:2:0:0";
  my.gnome.enable = true;             # GNOME + GDM + extensions + GNOME Software
  my.macos.enable = true;             # Giao diện giống macOS (WhiteSur + dock + menu)
  my.power.enable = true;             # Suspend s2idle + TLP + thức dậy bằng bàn phím
  my.audio.enable = true;             # PipeWire + mic ảo khử tiếng ồn (rnnoise)
  my.assets.enable = true;            # Fonts + wallpapers cục bộ (offline)

  # ==== Cấu hình riêng của host này ====
  networking.hostName = "lg";

  # Tag tự cập nhật theo mẫu "NixOS-YY.MM.DD-HH:MM" mỗi lần switch.
  # Inject qua env NIXOS_TAG + `nixos-rebuild --impure` (alias sw/bt trong
  # modules/shell.nix). LƯU Ý: nixpkgs chỉ cho phép ký tự [a-zA-Z0-9:_.-] trong
  # tag (tag được ghép vào system.nixos.label cho boot menu) nên mẫu gốc
  # "NixOS (YY/mm/dd-hh:mm)" phải viết lại: "/" → ".", "( )" → "-".
  # tryEval để flake vẫn eval được ở chế độ pure (nix flake check / CI).
  system.nixos.tags = let
    tag = (builtins.tryEval (builtins.getEnv "NIXOS_TAG")).value or "";
  in lib.optional (tag != "") tag;
  system.stateVersion = "25.11";
}
