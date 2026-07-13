# customized.nix — BamOS Edition Configuration
# File này được sinh tự động bởi Calamares installer dựa trên
# lựa chọn Edition + Machine Type của người dùng.
#
# Có thể chỉnh sửa thủ công để thay đổi edition sau này:
#   - bamos.nixosModules.standard
#   - bamos.nixosModules.developers
#   - bamos.nixosModules.gaming
#   - bamos.nixosModules.studio
#
# 📝 Bạn có thể thay đổi edition bất cứ lúc nào:
#   1. Sửa dòng imports bên dưới
#   2. sudo nixos-rebuild switch --flake /etc/nixos#bamos
#
{ lib, ... }:

{
  # Edition chọn khi cài đặt (standard/developers/gaming/studio)
  # Được Calamares điền tự động — có thể sửa tay
  imports = [
    bamos.nixosModules.standard
  ];

  # Power Management theo machine type
  bamos.power-management = {
    enable = true;
    profile = "desktop";
    ppdSupport = true;
    dynamicTuning = true;
    batteryOptimized = false;
  };

  # Third-party runtime (AppImage, Flatpak, FHS)
  bamos.third-party.fhs-compat = true;
}
