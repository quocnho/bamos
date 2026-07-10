{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/hardware/nvidia.nix
    ../../modules/hardware/detect.nix
    ../../modules/desktop/software-center.nix
  ];

  # ═══════════════════════════════════════════════
  # Tự động quét hardware trước mỗi lần rebuild
  # Chạy: sudo bamos-detect-hardware
  # ═══════════════════════════════════════════════
  bamos.hardware.detect = true;

  # ═══════════════════════════════════════════════
  # Override user mặc định — dùng quocnho cho laptop LG
  # ═══════════════════════════════════════════════
  bamos.user = {
    name = "quocnho";
    description = "Nguyễn Quốc Nho";
  };

  networking.hostName = "lg";
  system.stateVersion = "26.05";

  programs.firefox.enable = true;

  # ═══════════════════════════════════════════════
  # NVIDIA GeForce GTX 1650 (Turing TU117)
  # Laptop Optimus: Intel iGPU + NVIDIA dGPU
  # ═══════════════════════════════════════════════
  bamos.nvidia = {
    enable = true;
    # GTX 1650 là Turing — open kernel module có hỗ trợ nhưng
    # dùng proprietary (open = false) cho ổn định nhất.
    # Nếu muốn thử open module: set open = true
    open = false;
    # mode = "nvidia": Chỉ dùng GPU rời, hiệu năng tối đa
    # mode = "async":   Dùng Intel iGPU cho desktop, NVIDIA cho game
    mode = "nvidia";
    prime = {
      # Bus IDs cho LG Gram + GTX 1650:
      # Intel iGPU: PCI:0:2:0 (00:02.0)
      # NVIDIA dGPU: PCI:2:0:0 (02:00.0) — xác nhận qua lspci | grep -E "(VGA|3D)"
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:2:0:0";
    };
    powerManagement = {
      enable = true;
      finegrained = true;
    };
  };

  # ═══════════════════════════════════════════════
  # Software Center — GNOME Software + Flatpak + AppImage
  # Chỉ thêm Flathub, KHÔNG tự động cài 20 curated apps
  # ═══════════════════════════════════════════════
  bamos.software-center = {
    enable = true;
    desktop = "gnome";
    autoAddFlathub = true;
    installCuratedApps = false;
    extraFlatpakApps = [ ];
  };

  # ═══════════════════════════════════════════════
  # Auto-update (GLF-OS pattern)
  # ═══════════════════════════════════════════════
  bamos.update.autoUpgrade = true;

  # ═══════════════════════════════════════════════
  # Power Management — case study LG Gram
  #   CPU: i5-10210U (8 cores, 1.6-4.2 GHz)
  #   GPU: Intel UHD + NVIDIA GTX 1650 (offload)
  #   Disk: NVMe 476GB, 15GB RAM
  # ═══════════════════════════════════════════════
  bamos.power-management = {
    enable = true;
    profile = "desktop";
    ppdSupport = true;
    dynamicTuning = true;
    batteryOptimized = true;
    enableSwap = true;
    swapSize = 16384;
  };

  # VM & Container
  virtualisation = {
    libvirtd.enable = true;
    # Sử dụng Podman thay Docker
    podman.enable = true;
    virtualbox.host.enable = true;
  };

  # Developer tools + VM tools + GNOME extensions
  environment.systemPackages = with pkgs; [
    # VM tools
    qemu
    virt-manager
    virt-viewer
    quickemu
    OVMF

    # Nix dev
    nil
    nixd
    nixpkgs-fmt
    deadnix
    statix
    nix-output-monitor
    nix-tree
    nix-index
    cachix

    # Version control
    gh
    git-crypt
    git-lfs
    delta

    # Editors
    # vscode
    zed-editor

    # Terminal (giữ lại tmux, zsh)
    tmux
    zsh
    oh-my-zsh

    # Containers
    distrobox
    podman-compose

    # System tools
    unar
    ripgrep
    fd
    fzf

    # NVIDIA monitoring — cài qua flatpak: flatpak install flathub io.netapp.Nvtop

    # GNOME extensions
    gnomeExtensions.dash-to-dock
    gnomeExtensions.vitals
    # gnomeExtensions.gsconnect
    gnomeExtensions.user-themes
    gnomeExtensions.clipboard-indicator
    gnomeExtensions.caffeine
    # gnomeExtensions.gtile
    gnomeExtensions.appindicator
  ];

  # User groups — thêm groups cho quocnho
  users.users.${config.bamos.user.name}.extraGroups = [
    "libvirtd"
    "podman"
    "vboxusers"
  ];
}
