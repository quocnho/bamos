{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Base tools
    curl
    git
    fzf
    ripgrep
    # vim
    zed-editor
    # bluez
    # Secret management (age encryption)
    age
    ssh-to-age
    ragenix # agenix CLI (ragenix = Rust implementation)

    nil
    nixpkgs-fmt
    nixd

    # ═══════════════════════════════════════════════════════
    # Hardware detection tools (cho mọi edition + hosts)
    # ═══════════════════════════════════════════════════════
    pciutils # lspci — PCI device list (GPU, NVMe, etc.)
    usbutils # lsusb — USB device list
    dmidecode # DMI/SMBIOS — RAM, BIOS, motherboard info
    inxi # System info tổng hợp (GPU, CPU, disk, network)
    mesa-demos # glxinfo, eglinfo — OpenGL/Vulkan info
  ];
}
