# Description: Giao diện GNOME Desktop + GDM aggregator (< 45 dòng)
{ config, lib, ... }:

let
  cfg = config.my.gnome;
in
{
  imports = [
    ./extensions.nix
    ./dconf.nix
    ./keybindings.nix
    ./store.nix
  ];

  options.my.gnome = {
    enable = lib.mkEnableOption "GNOME desktop";

    store = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        GNOME Software ("App Store") + Flatpak backend.
        Bật cho máy người dùng cuối (cài app qua store). Máy DEVELOPER nên tắt
        (my.gnome.store = false): tiết kiệm ~160MB RAM & tiến trình ngầm.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.xserver.enable = true;
    services.displayManager.gdm.enable = true;
    services.desktopManager.gnome.enable = true;
  };
}
