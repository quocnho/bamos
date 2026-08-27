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

    # Audio / Ghi âm (tham khảo GLF-OS)
    ffmpeg

    # Dev Environment (devenv — devshell kiểu Nix, chạy cùng direnv)
    devenv

    # ==== Antigravity (Google — AI IDE + CLI, unfree) ====
    # - antigravity-ide: IDE nhánh VSCode 1.107 (bản 2.5.5 — dòng "Antigravity 2.0")
    # - antigravity-cli:  TUI agent client, lệnh `agy`
    antigravity-ide
    antigravity-cli

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

    # GNOME Extensions & Tools (bản đầy đủ trong modules/gnome.nix)
    gnome-extension-manager
  ];
}
