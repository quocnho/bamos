# Description: Cài đặt Dconf mặc định cho GNOME (dock, animations, fonts, mutter)
{ config, lib, ... }:

let
  cfg = config.my.gnome;
in
{
  programs.dconf.profiles.user.databases = [
    {
      settings = {
        # Tắt animation → giảm tải GPU/CPU (iGPU) — tiết kiệm pin
        "org/gnome/desktop/interface" = {
          enable-animations = false;
          font-antialiasing = "rgba";
          font-hinting = "full";
          font-rgba-order = "rgb";
        };

        # Numlock bật sẵn
        "org/gnome/desktop/peripherals/keyboard" = {
          numlock-state = true;
        };

        # Extension bật sẵn
        "org/gnome/shell" = {
          disable-user-extensions = false;
          enabled-extensions = [
            "dash-to-dock@micxgx.gmail.com"
            "arcmenu@arcmenu.com"
            "blur-my-shell@aunetx"
            "appindicatorsupport@rgcjonas.gmail.com"
            "caffeine@patapon.info"
            "quick-settings-audio-panel@rayzeq.github.io"
          ];
          favorite-apps = [
            "firefox.desktop"
            "org.gnome.Nautilus.desktop"
          ] ++ lib.optionals cfg.store [ "org.gnome.Software.desktop" ];
        };

        # Dash to Dock
        "org/gnome/shell/extensions/dash-to-dock" = {
          click-action = "minimize-or-overview";
          disable-overview-on-startup = true;
          dock-position = "BOTTOM";
          running-indicator-style = "DOTS";
          isolate-monitor = false;
          multi-monitor = true;
          show-mounts-network = true;
          always-center-icons = true;
          custom-theme-shrink = true;
        };

        # Mutter
        "org/gnome/mutter" = {
          dynamic-workspaces = true;
          edge-tiling = true;
        };
      };
    }
  ];
}
