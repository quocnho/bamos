# profiles/gnome-standard.nix
# GNOME Standard Edition — tổ hợp modules cho người dùng phổ thông
{ config
, pkgs
, lib
, ...
}:

{
  imports = [
    # Core system
    ../modules/core/system.nix
    ../modules/core/locale.nix
    ../modules/core/audio.nix
    ../modules/core/input-method.nix
    ../modules/core/optimization.nix

    # Desktop
    ../modules/desktop/gnome.nix

    # Hardware (generic)
    ../modules/hardware/network.nix

    # Fonts + apps + software center
    ../modules/core/fonts.nix
    ../modules/apps/standard.nix
    ../modules/desktop/software-center.nix
  ];

  nixpkgs.config.allowUnfree = lib.mkDefault true;

  bamos.software-center = {
    enable = true;
    desktop = "gnome";
    autoAddFlathub = true;
    installCuratedApps = false;
  };
}
