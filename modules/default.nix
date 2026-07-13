{
  imports = [
    # ═══ Overlay (phải đặt đầu để pkgs có sẵn cho các module sau) ═══
    ./core/bamos-overlay.nix

    # ═══ Core ═══
    ./core/system.nix
    ./core/packages.nix
    ./core/input-method.nix
    ./core/locale.nix
    ./core/audio.nix
    ./core/user.nix
    ./core/optimization.nix
    ./core/third-party.nix
    ./core/version.nix
    ./core/update.nix
    ./core/welcome.nix

    # ═══ Hardware ═══
    ./hardware/bluetooth.nix
    ./hardware/network.nix
    ./hardware/power-management.nix
    ./hardware/nvidia.nix
    ./hardware/detect.nix
    ./hardware/backup.nix

    # ═══ Desktop ═══
    ./desktop/gnome.nix

    # ═══ Theming ═══
    ./theming/bamos-branding.nix
    ./theming/gtk-theme.nix
  ];
}
