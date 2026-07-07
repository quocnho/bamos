# hosts/iso/configuration-kde.nix
# ISO-specific NixOS configuration — KDE Standard Edition
{ config
, pkgs
, lib
, ...
}:

{
  # Hardware detection script (chạy sau cài đặt)
  bamos.hardware.detect = true;

  # GDM sẽ gây conflict với SDDM → disable
  services.displayManager.gdm.enable = lib.mkForce false;

  # Seahorse (GNOME keyring) conflicts with KDE ksssaskpass
  programs.seahorse.enable = lib.mkForce false;

  # Live user
  users.users.nixos = {
    isNormalUser = true;
    initialPassword = "";
    extraGroups = [ "networkmanager" "wheel" "render" ];
  };
  services.displayManager.autoLogin = {
    enable = true;
    user = "nixos";
  };

  # Kernel: LTS
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_6_12;

  # Locale
  i18n.defaultLocale = "en_US.UTF-8";
  console.useXkbConfig = true;
  services.xserver.xkb.layout = "us";

  # Identity
  networking.hostName = "bamos-kde";

  # Size optimization
  documentation.enable = lib.mkForce false;
  documentation.man.enable = lib.mkForce false;
  documentation.info.enable = lib.mkForce false;
  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" "vi_VN.UTF-8/UTF-8" ];

  # Unfree
  nixpkgs.config = {
    allowUnfree = true;
    allowBroken = true;
    permittedInsecurePackages = [ "electron-39.8.10" ];
  };

  # ISO Image
  isoImage = {
    volumeID = "BAMOS-KDE";
    appendToMenuLabel = " BamOS KDE Standard";
    includeSystemBuildDependencies = false;
    squashfsCompression = "zstd -Xcompression-level 22";
    makeEfiBootable = true;
    makeUsbBootable = true;
  };
}
