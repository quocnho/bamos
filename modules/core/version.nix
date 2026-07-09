# modules/core/version.nix
# BamOS version identification — ghi đè /etc/os-release + /etc/lsb-release
# Tham khảo: GLF-OS version.nix pattern
{ config, lib, pkgs, ... }:

let
  DISTRO_NAME = "BamOS";
  DISTRO_ID = "bamos";
  CODENAME = "FPT"; # Đổi sau

  cfg = config.system.nixos;
in
{
  options.bamos.version = {
    enable = lib.mkEnableOption "BamOS version branding" // { default = true; };
    currentVersion = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0";
      description = "Phiên bản BamOS hiện tại (từ VERSION file)";
    };
    distroName = lib.mkOption {
      type = lib.types.str;
      default = DISTRO_NAME;
    };
    distroId = lib.mkOption {
      type = lib.types.str;
      default = DISTRO_ID;
    };
    codename = lib.mkOption {
      type = lib.types.str;
      default = CODENAME;
    };
  };

  config = lib.mkIf config.bamos.version.enable {
    # ═══════════════════════════════════════════════════════
    # /etc/os-release — chuẩn freedesktop
    # ═══════════════════════════════════════════════════════
    environment.etc."os-release".text = lib.mkForce ''
      NAME="${config.bamos.version.distroName}"
      ID="${config.bamos.version.distroId}"
      VERSION="${cfg.release} (${cfg.codeName})"
      VERSION_CODENAME="${config.bamos.version.codename}"
      VERSION_ID="${cfg.release}"
      BUILD_ID="${cfg.version}"
      PRETTY_NAME="${config.bamos.version.distroName} ${cfg.release} (${config.bamos.version.codename})"
      LOGO="bamos-logo"
      HOME_URL="https://github.com/quocnho/bamos"
      DOCUMENTATION_URL=""
      SUPPORT_URL=""
      BUG_REPORT_URL="https://github.com/quocnho/bamos/issues"
    '';

    # ═══════════════════════════════════════════════════════
    # /etc/lsb-release — tương thích Linux Standard Base
    # ═══════════════════════════════════════════════════════
    environment.etc."lsb-release".text = lib.mkForce ''
      LSB_VERSION="${cfg.release} (${cfg.codeName})"
      DISTRIB_ID="${config.bamos.version.distroId}"
      DISTRIB_RELEASE="${cfg.release}"
      DISTRIB_CODENAME="${lib.toLower config.bamos.version.codename}"
      DISTRIB_DESCRIPTION="${config.bamos.version.distroName} ${cfg.release} (${config.bamos.version.codename})"
    '';

    # ═══════════════════════════════════════════════════════
    # Distro name trong NixOS system
    # ═══════════════════════════════════════════════════════
    system.nixos.distroName = config.bamos.version.distroName;
    system.nixos.distroId = config.bamos.version.distroId;
  };
}
