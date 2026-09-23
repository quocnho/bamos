# Description: Local assets aggregator (< 35 dòng)
{ config, lib, pkgs, ... }:

let
  cfg = config.my.assets;
  localFonts = pkgs.callPackage ../../assets/fonts/fonts.nix { };
  fontsModule = import ./fonts.nix { inherit pkgs localFonts; };
in
{
  imports = [
    ./wallpapers.nix
  ];

  options.my.assets = {
    enable = lib.mkEnableOption "local assets (fonts + wallpapers, offline)";
  };

  config = lib.mkIf cfg.enable fontsModule;
}
