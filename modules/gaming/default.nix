# Description: Gaming module aggregator & options (< 45 dòng)
{ config, lib, ... }:

let
  cfg = config.my.gaming;
in
{
  imports = [
    ./steam.nix
    ./optimizations.nix
  ];

  options.my.gaming = {
    enable = lib.mkEnableOption "gaming profile (Steam, GameMode, MangoHud, Proton)";

    steam = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Cài đặt và cấu hình Steam với firewall.";
    };

    gamemode = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Bật Feral GameMode tự động tối ưu CPU Governor và I/O.";
    };

    mangohud = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Cài đặt MangoHud theo dõi FPS, nhiệt độ GPU/CPU.";
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.config.allowUnfree = true;
  };
}
