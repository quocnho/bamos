# Host "lg" — LG laptop (Intel UHD CometLake + NVIDIA GTX 1650).
#
# = Desktop profile (common + gnome + macos + boot + assets)
# = Phần riêng máy này: GPU (my.gpu + bus IDs), nguồn điện (my.power), user.
#
# Lưu ý: user "quocnho" khai báo TRỰC TIẾP ở đây (không hardcode trong
# modules/) — máy khác cài qua ISO tự tạo user riêng ở bước Users của Calamares.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../profiles/desktop.nix
    ../hardware-configuration.nix
  ];

  networking.hostName = "lg";

  # ==== Người dùng (riêng host này) ====
  # initialPassword chỉ dùng lần đăng nhập đầu — đổi ngay sau khi vào máy:
  #   passwd
  users.users.quocnho = {
    isNormalUser = true;
    description = "quocnho";
    # extraGroups đầy đủ: wifi (networkmanager), bluetooth, input, video/audio,
    # in ấn (lp/scanner), mount ổ đĩa (disk/storage), sudo (wheel), podman...
    extraGroups = [
      "networkmanager"
      "wheel"
      "bluetooth"
      "input"
      "video"
      "audio"
      "render"
      "disk"
      "storage"
      "lp"
      "scanner"
      "power"
      "podman"
    ];
    initialPassword = "j";
    shell = pkgs.zsh;
  };

  # ==== Phần riêng của máy LG ====
  my.dev.enable = true; # công cụ dev: Zed, Antigravity, Python, Node, devenv...
  my.gpu.enable = true;
  my.gpu.intelBusId = "PCI:0:2:0";
  my.gpu.nvidiaBusId = "PCI:2:0:0";

  my.power.enable = true; # s2idle + TLP + Battery Care 80%

  # (Tag generation "NixOS-YY.MM.DD-HH:MM" giờ nằm ở profiles/common.nix — mọi máy)
  system.stateVersion = "25.11";
}

# bamos installer
