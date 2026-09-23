# Description: GameMode, MangoHud, sysctl tweaks & gaming packages
{ config, lib, pkgs, ... }:

let
  cfg = config.my.gaming;
in
{
  config = lib.mkIf cfg.enable {
    programs.gamemode = lib.mkIf cfg.gamemode {
      enable = true;
      settings = {
        general.renice = 10;
        custom = {
          start = "${pkgs.libnotify}/bin/notify-send 'GameMode' 'GameMode đã được kích hoạt'";
          end = "${pkgs.libnotify}/bin/notify-send 'GameMode' 'GameMode đã kết thúc'";
        };
      };
    };

    environment.systemPackages = with pkgs; [
      protonup-qt
      lutris
      bottles
      (lib.mkIf cfg.mangohud mangohud)
      gamescope
    ];

    boot.kernel.sysctl = {
      "vm.max_map_count" = 2147483642;
      "vm.swappiness" = 10;
    };
  };
}
