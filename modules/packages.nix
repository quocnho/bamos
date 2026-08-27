# Gói phần mềm cài sẵn toàn hệ thống.
{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Core Tools
    zed-editor
    git
    vim
    wget
    curl
    distrobox
    mesa-demos
    pciutils
    firefox
    gparted
    unzip
    zip
    unrar

    # Touchpad Gestures
    libinput-gestures
    xdotool

    # Terminal UI
    starship
    fd
    fzf
    bat
    htop
    direnv
    podman-compose

    # GNOME Extensions & Tools
    gnomeExtensions.caffeine
    gnomeExtensions.appindicator
    gnome-extension-manager
  ];
}
