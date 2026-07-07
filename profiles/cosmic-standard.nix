# profiles/cosmic-standard.nix
# COSMIC Standard Edition — tổ hợp modules cho người dùng phổ thông
{ config
, pkgs
, lib
, ...
}:

{
  imports = [
    ../modules/core/system.nix
    ../modules/core/locale.nix
    ../modules/core/audio.nix
    ../modules/core/input-method.nix
    ../modules/core/optimization.nix

    ../modules/hardware/network.nix
    ../modules/core/fonts.nix
    ../modules/apps/standard.nix
    ../modules/desktop/cosmic.nix
  ];

  nixpkgs.config.allowUnfree = lib.mkDefault true;
}
