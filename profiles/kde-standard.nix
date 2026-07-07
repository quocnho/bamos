# profiles/kde-standard.nix
# KDE Plasma Standard Edition — tổ hợp modules cho người dùng phổ thông
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

    # KDE Desktop
    ../modules/desktop/kde.nix

    # Hardware (generic)
    ../modules/hardware/network.nix

    # Fonts
    ../modules/core/fonts.nix

    # Standard apps
    ../modules/apps/standard.nix

    # Software Center (KDE Discover + Flathub + AppImage)
    ../modules/desktop/software-center.nix
  ];

  nixpkgs.config.allowUnfree = lib.mkDefault true;

  bamos.software-center = {
    enable = true;
    desktop = "kde";
    autoAddFlathub = true;
    installCuratedApps = false;
  };
}
