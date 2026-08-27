# Giao diện GNOME + GDM + cài đặt dconf mặc định.
# Tham khảo `environments/gnome.nix` của GLF-OS (bộ extensions & tools).
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

    # GNOME Software ("App Store") + Flatpak backend (GLF-OS cũng dùng Flatpak)
    services.gnome.gnome-software.enable = true;
    services.flatpak.enable = true;

    environment.gnome.excludePackages = with pkgs; [
      gnome-tour
      totem
      yelp
      gnome-contacts
      gnome-weather
      gnome-maps
    ];

    environment.systemPackages = with pkgs; [
      gnome-tweaks

      # ==== GNOME Extensions (bộ của GLF-OS) ====
      gnomeExtensions.caffeine
      gnomeExtensions.appindicator
      # gnomeExtensions.gsconnect
      gnomeExtensions.dash-to-dock
      # gnomeExtensions.dash-to-panel
      gnomeExtensions.arcmenu
      gnomeExtensions.blur-my-shell
      # gnomeExtensions.open-bar
      gnomeExtensions.burn-my-windows
      gnomeExtensions.tiling-shell
      gnomeExtensions.vitals
      gnomeExtensions.quick-settings-audio-panel
      gnomeExtensions.rounded-window-corners-reborn
      gnomeExtensions.bluetooth-battery-meter
      # gnomeExtensions.bing-wallpaper-changer
    ];

    programs.dconf.profiles.user.databases = [{
      settings = {
        "org/gnome/desktop/wm/keybindings" = {
          switch-to-workspace-left = [ "<Control><Super>Left" ];
          switch-to-workspace-right = [ "<Control><Super>Right" ];
          switch-applications = [ "<Super>Tab" "<Alt>Tab" ];
        };

        # Touchpad & keyboard (giá trị GLF-OS)
        "org/gnome/desktop/peripherals/touchpad" = {
          click-method = "areas";
          tap-to-click = true;
          two-finger-scrolling-enabled = true;
        };
        "org/gnome/desktop/peripherals/keyboard" = {
          numlock-state = true;
        };

        # Extension bật sẵn (UUID đã kiểm chứng trong nixpkgs)
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
            "org.gnome.Software.desktop"
          ];
        };

        # Dock (giá trị GLF-OS)
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

        "org/gnome/mutter" = {
          dynamic-workspaces = true;
          edge-tiling = true;
        };
      };
    }];
  };
}
