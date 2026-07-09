{ config, lib, pkgs, ... }:

{
  # BamOS custom packages overlay
  nixpkgs.overlays = [
    (final: prev: {
      bamos-branding = final.callPackage ../../pkgs/bamos-branding { };
      bam-cli = final.callPackage ../../pkgs/bam-cli { };
    })
  ];

  # Kích hoạt tính năng Flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Kernel Zen
  boot.kernelPackages = pkgs.linuxPackages_zen;

  # Hostname — mặc định "bamos", override ở host/profile level
  networking.hostName = lib.mkDefault "bamos";

  # Cho phép unfree packages
  nixpkgs.config.allowUnfree = true;

  # ═══════════════════════════════════════════════════════
  # BamOS Binary Cache (Cachix)
  # Tự động pull packages từ cache — không cần build từ source
  # ═══════════════════════════════════════════════════════
  nix.settings.extra-substituters = [ "https://bamos.cachix.org" ];
  nix.settings.extra-trusted-public-keys = [
    "bamos.cachix.org-1:ZquC3WpAg/VIEGb0cGBRl0RerTgx3gISsmGHMa9AMIY="
  ];
}
