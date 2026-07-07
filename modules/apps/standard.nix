# modules/apps/standard.nix
# Standard Edition applications — người dùng phổ thông
# Bao gồm: browser, office, media, utilities
{ pkgs
, ...
}:

{
  environment.systemPackages = with pkgs; [
    # Web
    firefox
    chromium

    # Office
    evince # PDF viewer

    # Media
    vlc
    mpv
    imv # Image viewer
    ffmpeg

    # Communication

    # Utilities
    gnome-calculator
    gnome-calendar
    gnome-contacts
    gnome-logs
    gnome-font-viewer
    baobab # Disk usage analyzer

    # Archive
    file-roller
    p7zip
    unzip
    unrar
  ];
}
