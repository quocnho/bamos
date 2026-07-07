{ lib, pkgs, ... }:

{
  imports = [
    ../theming/gnome-theme.nix
  ];

  # X11 windowing system
  services.xserver.enable = true;

  # GNOME Desktop Environment
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Keymap
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Tắt bloatware GNOME
  services.gnome.evolution-data-server.enable = lib.mkForce false;
}
