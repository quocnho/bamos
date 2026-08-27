# Giao diện GNOME + GDM + cài đặt dconf mặc định.
{ config, lib, pkgs, ... }:

let
  cfg = config.my.gnome;
in
{
  options.my.gnome = {
    enable = lib.mkEnableOption "GNOME desktop";
  };

  config = lib.mkIf cfg.enable {
    services.xserver.enable = true;
    services.displayManager.gdm.enable = true;
    services.desktopManager.gnome.enable = true;

    environment.gnome.excludePackages = with pkgs; [
      gnome-tour
      totem
      yelp
      gnome-contacts
      gnome-weather
      gnome-maps
    ];

    programs.dconf.profiles.user.databases = [{
      settings = {
        "org/gnome/desktop/wm/preferences" = {
          button-layout = ":minimize,maximize,close";
        };
        "org/gnome/desktop/wm/keybindings" = {
          switch-to-workspace-left = [ "<Control><Super>Left" ];
          switch-to-workspace-right = [ "<Control><Super>Right" ];
          switch-applications = [ "<Super>Tab" "<Alt>Tab" ];
        };
      };
    }];
  };
}
