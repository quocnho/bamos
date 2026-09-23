# Description: Studio aggregator (< 30 dòng)
{ config, lib, pkgs, ... }:

let
  cfg = config.my.studio;
  creatorFonts = import ./fonts.nix { inherit pkgs; };
in
{
  imports = [
    ./options.nix
    ./obs.nix
    ./production.nix
  ];

  config = lib.mkIf (cfg.enable && cfg.fonts) {
    fonts.packages = creatorFonts;
  };
}
