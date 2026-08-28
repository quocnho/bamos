# Host "lg" — LG laptop (Intel UHD CometLake + NVIDIA GTX 1650).
#
# = Desktop profile (common + gnome + macos + boot + assets)
# = Phần riêng máy này: GPU (my.gpu + bus IDs), nguồn điện (my.power), user.
#
# Lưu ý: modules/users.nix tạo user "quocnho" — chỉ import ở host này,
# KHÔNG nằm trong modules/default.nix (để máy khác cài qua ISO tự tạo user).
{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../profiles/desktop.nix
    ../modules/users.nix
    ../hardware-configuration.nix
  ];

  networking.hostName = "lg";

  # ==== Phần riêng của máy LG ====
  my.gpu.enable = true;
  my.gpu.intelBusId = "PCI:0:2:0";
  my.gpu.nvidiaBusId = "PCI:2:0:0";

  my.power.enable = true; # s2idle + TLP + Battery Care 80%

  # Tag tự cập nhật theo mẫu "NixOS-YY.MM.DD-HH:MM" mỗi lần switch.
  # Inject qua env NIXOS_TAG + `nixos-rebuild --impure` (alias sw/bt trong
  # modules/shell.nix). LƯU Ý: nixpkgs chỉ cho phép ký tự [a-zA-Z0-9:_.-] trong
  # tag (tag được ghép vào system.nixos.label cho boot menu) nên mẫu gốc
  # "NixOS (YY/mm/dd-hh:mm)" phải viết lại: "/" → ".", "( )" → "-".
  # tryEval để flake vẫn eval được ở chế độ pure (nix flake check / CI).
  system.nixos.tags =
    let
      tag = (builtins.tryEval (builtins.getEnv "NIXOS_TAG")).value or "";
    in
    lib.optional (tag != "") tag;

  system.stateVersion = "25.11";
}
