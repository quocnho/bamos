# modules/theming/bamos-branding.nix
# BamOS branding — bamboo logos, wallpapers, Plymouth boot screen
# Sử dụng package bamos-branding từ pkgs/
# Logo: Bamboo hexagonal mosaic (6 segments) — "Cây tre trăm đốt"
# Inspired by GLF-OS branding pattern
{ pkgs, ... }:

let
  brandingPkg = pkgs.bamos-branding;
in
{
  # Install branding package (logos, wallpapers, GNOME background XML)
  environment.systemPackages = [ brandingPkg ];

  # ═══════════════════════════════════════════════════════
  # Plymouth boot splash — bamboo logo + spinner
  # ═══════════════════════════════════════════════════════
  boot.plymouth.enable = true;
  boot.plymouth.logo = "${brandingPkg}/share/icons/hicolor/scalable/apps/bamos-logo.svg";
  boot.plymouth.theme = "bgrt"; # Uses firmware logo + spinner by default

  # ═══════════════════════════════════════════════════════
  # Logo trong /etc/os-release (logo icon)
  # ═══════════════════════════════════════════════════════
  environment.etc."bamos/logo.svg".source = "${brandingPkg}/share/icons/hicolor/scalable/apps/bamos-logo.svg";

  # ═══════════════════════════════════════════════════════
  # GNOME: default wallpaper + bamboo logo lock screen
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
      "org/gnome/desktop/interface" = {
        # Bamboo green accent color
        accent-color = "green";
      };
    };
  }];
}
