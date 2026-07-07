# hosts/iso/configuration-studio.nix
# ISO — Studio Edition (dùng chung cho GNOME/KDE/COSMIC)
{ config, pkgs, lib, ... }: {
  bamos.hardware.detect = true;
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_6_12;
  networking.hostName = "bamos-studio";
  users.users.nixos = {
    isNormalUser = true;
    initialPassword = "";
    extraGroups = [ "networkmanager" "wheel" "render" "audio" ];
  };
  services.displayManager.autoLogin = { enable = true; user = "nixos"; };
  # Tắt GDM để tránh conflict với SDDM (KDE) hoặc cosmic-greeter (COSMIC)
  services.displayManager.gdm.enable = lib.mkForce false;

  # Tắt Seahorse (GNOME keyring) để tránh conflict với KDE wallet
  programs.seahorse.enable = lib.mkForce false;

  i18n.defaultLocale = "en_US.UTF-8";
  documentation.enable = lib.mkForce false;
  nixpkgs.config = { allowUnfree = true; allowBroken = true; permittedInsecurePackages = [ "electron-39.8.10" ]; };
  isoImage = {
    volumeID = "BAMOS-STUDIO";
    appendToMenuLabel = " BamOS Studio";
    includeSystemBuildDependencies = false;
    squashfsCompression = "zstd -Xcompression-level 22";
    makeEfiBootable = true;
    makeUsbBootable = true;
  };
}
