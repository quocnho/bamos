# Description: Auto-update module aggregator & timer (< 35 dòng)
{ config, lib, ... }:

let
  cfg = config.my.update;
in
{
  imports = [
    ./services.nix
  ];

  options.my.update.enable = lib.mkOption {
    description = "Tự động cập nhật hệ thống từ GitHub (systemd timer + thông báo)";
    type = lib.types.bool;
    default = false;
  };

  config = lib.mkIf cfg.enable {
    systemd.timers."bamos-update" = {
      description = "Bamos auto-update timer (12h)";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "10min";
        OnUnitActiveSec = "12h";
        RandomizedDelaySec = "1h";
      };
    };
  };
}
