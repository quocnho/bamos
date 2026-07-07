{
  imports = [
    ./core/system.nix
    ./core/packages.nix
    ./core/input-method.nix
    ./core/locale.nix
    ./hardware/bluetooth.nix
    ./hardware/network.nix
    ./hardware/power-management.nix
    ./desktop/gnome.nix
    ./core/audio.nix
    ./core/user.nix
    ./core/optimization.nix
    ./theming/bamos-branding.nix
    ./theming/gtk-theme.nix
  ];
}
