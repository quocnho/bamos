# Description: Danh sách packages loại trừ & GNOME extensions
{ pkgs, ... }:

{
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    totem
    yelp
    gnome-contacts
    gnome-weather
    gnome-maps
  ];

  environment.systemPackages = with pkgs; [
    gnome-tweaks

    # ==== GNOME Extensions (bộ của GLF-OS) ====
    gnomeExtensions.caffeine
    gnomeExtensions.appindicator
    gnomeExtensions.dash-to-dock
    gnomeExtensions.arcmenu
    gnomeExtensions.blur-my-shell
    gnomeExtensions.open-bar
    gnomeExtensions.burn-my-windows
    gnomeExtensions.tiling-shell
    gnomeExtensions.vitals
    gnomeExtensions.quick-settings-audio-panel
    gnomeExtensions.rounded-window-corners-reborn
    gnomeExtensions.bluetooth-battery-meter
  ];
}
