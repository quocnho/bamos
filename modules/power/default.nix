# Description: Quản lý năng lượng power aggregator (< 40 dòng)
{ config, lib, ... }:

let
  cfg = config.my.power;
in
{
  imports = [
    ./tlp.nix
    ./rtc-wakeup.nix
  ];

  options.my.power = {
    enable = lib.mkEnableOption "power management (s2idle + TLP)";
  };

  config = lib.mkIf cfg.enable {
    # Suspend DEEP (S3) qua kernel param
    boot.kernelParams = [ "mem_sleep_default=deep" ];

    # Gập nắp máy thì suspend
    services.logind.settings.Login.HandleLidSwitch = "suspend";

    # Quản lý nhiệt chủ động Intel Thermal Daemon
    services.thermald.enable = true;
  };
}
