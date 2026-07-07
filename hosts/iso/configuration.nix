# hosts/iso/configuration.nix
# ISO-specific NixOS configuration — GNOME Standard Edition
# Tham khảo: GLF-OS (https://framagit.org/gaming-linux-fr/glf-os/glf-os)
{ config
, pkgs
, lib
, ...
}:

{
  # ═══════════════════════════════════════════════════════
  # Hardware detection script (chạy sau cài đặt)
  # ═══════════════════════════════════════════════════════
  bamos.hardware.detect = true;

  # ═══════════════════════════════════════════════════════
  # Live user (không password — auto-login, base module set initialHashedPassword = "")
  # ═══════════════════════════════════════════════════════
  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [
      "networkmanager"
      "wheel"
      "render"
    ];
  };

  services.displayManager.autoLogin = {
    enable = true;
    user = "nixos";
  };

  # ═══════════════════════════════════════════════════════
  # Kernel: LTS cho ISO (tương thích ZFS + ổn định)
  # Host (lg) vẫn dùng Zen qua modules/system.nix
  # ═══════════════════════════════════════════════════════
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_6_12;

  # ═══════════════════════════════════════════════════════
  # Locale & Keyboard
  # ═══════════════════════════════════════════════════════
  i18n.defaultLocale = "en_US.UTF-8";
  console.useXkbConfig = true;
  services.xserver.xkb.layout = "us";

  # ═══════════════════════════════════════════════════════
  # System identity
  # ═══════════════════════════════════════════════════════
  networking.hostName = "bamos";

  # experimental-features đã được set trong modules/system.nix

  # ═══════════════════════════════════════════════════════
  # ISO Size Optimization
  # ═══════════════════════════════════════════════════════

  # Loại bỏ docs/man pages khỏi ISO — giảm ~200-300MB
  documentation.enable = lib.mkForce false;
  documentation.man.enable = lib.mkForce false;
  documentation.info.enable = lib.mkForce false;

  # Chỉ giữ en_US + vi_VN locale trong ISO (giảm ~100MB)
  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" "vi_VN.UTF-8/UTF-8" ];

  # ═══════════════════════════════════════════════════════
  # Package policy (GLF-OS pattern)
  # ═══════════════════════════════════════════════════════
  nixpkgs.config = {
    allowUnfree = true;
    allowBroken = true;
    permittedInsecurePackages = [
      "electron-39.8.10"
    ];
  };

  # ═══════════════════════════════════════════════════════
  # Custom config — nơi người dùng thêm cấu hình riêng
  # ═══════════════════════════════════════════════════════
  imports = [
    ./customConfig/default.nix
  ];

  # ═══════════════════════════════════════════════════════
  # ISO Image options (GLF-OS inspired)
  # ═══════════════════════════════════════════════════════
  isoImage = {
    volumeID = "BAMOS-GNOME";
    appendToMenuLabel = " BamOS GNOME Standard";
    includeSystemBuildDependencies = false;
    squashfsCompression = "zstd -Xcompression-level 22";
    makeEfiBootable = true;
    makeUsbBootable = true;
  };
}
