# modules/theming/bamos-branding.nix
# BamOS branding — wallpapers, logos, Plymouth boot screen
# Sử dụng package bamos-branding từ pkgs/
{ config, lib, pkgs, ... }:

let
  brandingPkg = pkgs.bamos-branding;
in
{
  # Install branding package (logos, wallpapers, GNOME background XML)
  environment.systemPackages = [ brandingPkg ];

  # ═══════════════════════════════════════════════════════
  # Plymouth boot splash
  # ═══════════════════════════════════════════════════════
  boot.plymouth.enable = true;
  boot.plymouth.logo = "${brandingPkg}/share/icons/hicolor/scalable/apps/bamos-logo.svg";

  # ═══════════════════════════════════════════════════════
  # GNOME: default wallpaper via dconf
  # ═══════════════════════════════════════════════════════
  programs.dconf.profiles.user.databases = [{
    settings = {
      "org/gnome/desktop/background" = {
        picture-uri = "file://${brandingPkg}/share/backgrounds/gnome/bamos-default.svg";
        picture-uri-dark = "file://${brandingPkg}/share/backgrounds/gnome/bamos-default-dark.svg";
        picture-options = "zoom";
        primary-color = "#1a1a2e";
      };
      "org/gnome/desktop/screensaver" = {
        picture-uri = "file://${brandingPkg}/share/backgrounds/gnome/bamos-default-dark.svg";
      };
    };
  }];
}
