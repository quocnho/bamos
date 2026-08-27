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
    gparted
    unzip
    zip
    unrar

    # Audio / Ghi âm (tham khảo GLF-OS)
    ffmpeg

    # Dev Environment (devenv — devshell kiểu Nix, chạy cùng direnv)
    devenv

    # ==== Python (môi trường lập trình — luôn sẵn sàng) ====
    python3
    python3Packages.pip
    python3Packages.virtualenv
    uv

    # ==== Antigravity (Google — AI IDE + CLI, unfree) ====
    antigravity-ide
    antigravity-cli

    # Terminal UI
    # (fzf + starship + zoxide được cài qua programs.* trong modules/shell.nix)
    fd
    bat
    eza
    htop
    direnv
    podman-compose

    # GNOME Extensions & Tools (bản đầy đủ trong modules/gnome.nix)
    gnome-extension-manager
  ];

  # ==== Firefox (cài qua programs.firefox để kèm policies tối ưu PIN) ====
  # - VAAPI hardware video decode trên Intel iGPU (iHD): xem video tiết kiệm pin
  # - Tự xả tab khi thiếu RAM
  programs.firefox = {
    enable = true;
    policies = {
      Preferences = {
        "media.ffmpeg.vaapi.enabled" = true;
        "media.hardware-video-decoding.enabled" = true;
        "browser.tabs.unloadOnLowMemory" = true;
      };
    };
  };
}
