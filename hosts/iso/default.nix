# hosts/iso/default.nix
{ self, inputs, ... }:
let
  inherit (inputs.nixpkgs) lib;
  installer = desktop: "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-${desktop}.nix";
  mkISO = { name, profile, desktop, isoConfig }:
    {
      flake.nixosConfigurations.${name} = lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          self.nixosModules.default
          (import ../../profiles/${profile}.nix)
          (installer desktop)
          "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
          inputs.disko.nixosModules.disko
          (import ../../modules/boot/disko-btrfs.nix)
          (import ../../modules/boot/calamares.nix)
          (import ../../modules/hardware/detect.nix)
          ./${isoConfig}
        ];
      };
    };
  variants = [
    { name = "iso-gnome-standard"; profile = "gnome-standard"; desktop = "gnome"; isoConfig = "configuration.nix"; }
    { name = "iso-gnome-developers"; profile = "gnome-developers"; desktop = "gnome"; isoConfig = "configuration.nix"; }
    { name = "iso-gnome-gaming"; profile = "gnome-gaming"; desktop = "gnome"; isoConfig = "configuration.nix"; }
    { name = "iso-gnome-studio"; profile = "gnome-studio"; desktop = "gnome"; isoConfig = "configuration-studio.nix"; }
    { name = "iso-kde-standard"; profile = "kde-standard"; desktop = "plasma6"; isoConfig = "configuration-kde.nix"; }
    { name = "iso-kde-developers"; profile = "kde-developers"; desktop = "plasma6"; isoConfig = "configuration-kde.nix"; }
    { name = "iso-kde-gaming"; profile = "kde-gaming"; desktop = "plasma6"; isoConfig = "configuration-kde.nix"; }
    { name = "iso-kde-studio"; profile = "kde-studio"; desktop = "plasma6"; isoConfig = "configuration-studio.nix"; }
    { name = "iso-cosmic-standard"; profile = "cosmic-standard"; desktop = "cosmic"; isoConfig = "configuration.nix"; }
    { name = "iso-cosmic-developers"; profile = "cosmic-developers"; desktop = "cosmic"; isoConfig = "configuration.nix"; }
    { name = "iso-cosmic-gaming"; profile = "cosmic-gaming"; desktop = "cosmic"; isoConfig = "configuration.nix"; }
    { name = "iso-cosmic-studio"; profile = "cosmic-studio"; desktop = "cosmic"; isoConfig = "configuration-studio.nix"; }
  ];
in
{
  flake.nixosConfigurations = builtins.foldl' (acc: v: acc // (mkISO v).flake.nixosConfigurations) { } variants;
}
