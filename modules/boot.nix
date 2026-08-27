# Bootloader, kernel & Plymouth (màn hình splash khi boot).
{ config, lib, pkgs, ... }:

let
  cfg = config.my.boot;
in
{
  options.my.boot = {
    enable = lib.mkEnableOption "bootloader & kernel (systemd-boot, Plymouth)";
  };

  config = lib.mkIf cfg.enable {
    boot.loader.systemd-boot.enable = true;
    boot.loader.systemd-boot.configurationLimit = 10;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.kernelPackages = pkgs.linuxPackages_latest;

    # Tắt chữ chạy khi boot, bật splash (Plymouth)
    boot.plymouth.enable = true;
    boot.consoleLogLevel = 0;
    boot.initrd.verbose = false;
    boot.kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "loglevel=3"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
    ];
  };
}
