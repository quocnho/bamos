# hosts/iso/default.nix
# Unified ISO builders — 3 ISOs (GNOME/KDE/COSMIC)
# Edition + Machine Type được chọn trong Calamares (packagechooser)
#
# Tham khảo: GLF-OS single ISO pattern
#   - 1 ISO config duy nhất cho mọi edition
#   - Edition/DE chọn khi install, không build riêng
#
{ self, inputs, ... }:
let
  inherit (inputs.nixpkgs) lib;
  installer = desktop: "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-${desktop}.nix";

  mkUnifiedISO = { name, desktop, profile, isoConfig }:
    {
      flake.nixosConfigurations.${name} = lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          # BamOS core modules
          self.nixosModules.default

          # Default profile (Edition được chọn trong Calamares)
          (import ../../profiles/${profile}.nix)

          # Calamares installer
          (installer desktop)
          "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"

          # Disk partitioning + Calamares config
          inputs.disko.nixosModules.disko
          (import ../../modules/boot/disko-btrfs.nix)
          (import ../../modules/boot/calamares.nix)

          # Hardware detection
          (import ../../modules/hardware/detect.nix)

          # ISO-specific config
          ./${isoConfig}
        ];
      };
    };

  # 3 unified ISOs — mỗi ISO chứa tất cả 4 editions
  # Người dùng chọn edition + machine type trong Calamares
  variants = [
    { name = "iso-gnome-unified"; profile = "gnome-standard"; desktop = "gnome"; isoConfig = "configuration.nix"; }
    { name = "iso-kde-unified"; profile = "kde-standard"; desktop = "plasma6"; isoConfig = "configuration-kde.nix"; }
    { name = "iso-cosmic-unified"; profile = "cosmic-standard"; desktop = "cosmic"; isoConfig = "configuration.nix"; }
  ];
in
{
  flake.nixosConfigurations = builtins.foldl' (acc: v: acc // (mkUnifiedISO v).flake.nixosConfigurations) { } variants;
}
