# Description: Bootloader, kernel packages selection & Plymouth aggregator (< 45 dòng)
{ config, lib, pkgs, ... }:

let
  cfg = config.my.boot;
in
{
  imports = [
    ./plymouth.nix
  ];

  options.my.boot = {
    enable = lib.mkEnableOption "bootloader & kernel (systemd-boot, Plymouth)";

    kernel = lib.mkOption {
      type = lib.types.enum [
        "default"
        "zen"
        "latest"
      ];
      default = "latest";
      description = ''
        Kernel cho máy:
        - "default": kernel mặc định nixpkgs (ổn định, pin tốt).
        - "zen": kernel desktop tối ưu độ mượt phản hồi.
        - "latest": kernel mainline mới nhất.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    boot.loader.systemd-boot.enable = true;
    boot.loader.systemd-boot.configurationLimit = 10;
    boot.loader.efi.canTouchEfiVariables = true;

    boot.kernelPackages = lib.mkDefault (
      if cfg.kernel == "zen" then
        pkgs.linuxPackages_zen
      else if cfg.kernel == "latest" then
        pkgs.linuxPackages_latest
      else
        pkgs.linuxPackages
    );
  };
}
