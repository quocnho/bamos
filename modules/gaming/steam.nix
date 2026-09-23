# Description: Cấu hình Steam client và firewall ports
{ config, lib, ... }:

let
  cfg = config.my.gaming;
in
{
  config = lib.mkIf (cfg.enable && cfg.steam) {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = false;
      localNetworkGameTransfers.openFirewall = true;
      gamescopeSession.enable = true;
    };
  };
}
