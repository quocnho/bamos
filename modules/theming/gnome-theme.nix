# modules/theming/gnome-theme.nix
# GNOME Shell theme configuration — RakuOS GNOME inspired
#
# RakuOS GNOME:
#   GTK Theme: OrigamiPaper (Nord palette)
#   Icons: WhiteSur-dark
#   Cursor: Bibata-Modern-Classic
#   Font: Inter 11, Maple Mono NF 11
#   Extensions: appindicator, no-overview, dash-to-dock, blur-my-shell
#   Color Scheme: prefer-dark
#
# BamOS equivalent (Nord palette):
#   GTK Theme: Nordic  (~ OrigamiPaper)
#   Icons: WhiteSur-dark (available in nixpkgs!)
#   Cursor: Bibata-Modern-Classic (available in nixpkgs!)
#   Font: Inter 11, Maple Mono NF 11
#   Extensions: appindicator, no-overview, dash-to-dock, blur-my-shell, user-themes
#
{ lib, pkgs, ... }:

let
  # Theme names (matching GNOME Shell expectations)
  gtkTheme = "Nordic";
  iconTheme = "WhiteSur-dark";
  cursorTheme = "Bibata-Modern-Classic";
  fontName = "Inter 11";
  monoFontName = "Maple Mono NF 11";

  # ═══════════════════════════════════════════════════════
  # GTK settings.ini — works IMMEDIATELY (unlike dconf)
  # GNOME reads /etc/gtk-3.0/settings.ini BEFORE dconf user db
  # ═══════════════════════════════════════════════════════
  gtkSettings = ''
    [Settings]
    gtk-theme-name=${gtkTheme}
    gtk-icon-theme-name=${iconTheme}
    gtk-cursor-theme-name=${cursorTheme}
    gtk-font-name=${fontName}
    gtk-monospace-font-name=${monoFontName}
    gtk-application-prefer-dark-theme=1
    gtk-error-bell=0
  '';

  # ═══════════════════════════════════════════════════════
  # First-login gsettings activator
  # Dành cho user ĐÃ TỒN TẠI — dconf user db ưu tiên cao hơn
  # Chạy 1 lần sau login để force-apply theme settings
  # ═══════════════════════════════════════════════════════
  gsettingsActivator = pkgs.writeShellApplication {
    name = "bamos-gnome-first-login";
    runtimeInputs = with pkgs; [ glib ];
    text = ''
      set -euo pipefail

      USER_HOME="$HOME"
      MARKER="$USER_HOME/.config/bamos-gnome-theme-applied"

      if [ -f "$MARKER" ]; then
        exit 0
      fi

      echo "🎨 BamOS: Applying GNOME theme (one-time setup)..."

      # GSettings — applies to current user immediately
      gsettings set org.gnome.desktop.interface gtk-theme "${gtkTheme}" 2>/dev/null || true
      gsettings set org.gnome.desktop.interface icon-theme "${iconTheme}" 2>/dev/null || true
      gsettings set org.gnome.desktop.interface cursor-theme "${cursorTheme}" 2>/dev/null || true
      gsettings set org.gnome.desktop.interface font-name "${fontName}" 2>/dev/null || true
      gsettings set org.gnome.desktop.interface document-font-name "${fontName}" 2>/dev/null || true
      gsettings set org.gnome.desktop.interface monospace-font-name "${monoFontName}" 2>/dev/null || true
      gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" 2>/dev/null || true

      # Window buttons
      gsettings set org.gnome.desktop.wm.preferences button-layout "appmenu:minimize,maximize,close" 2>/dev/null || true

      # Extensions
      gsettings set org.gnome.shell enabled-extensions "['appindicatorsupport@rgcjonas.gmail.com', 'dash-to-dock@micxgx.gmail.com', 'blur-my-shell@aunetx', 'no-overview@fthx', 'user-theme@gnome-shell-extensions.gcampax.github.com']" 2>/dev/null || true

      touch "$MARKER"
      echo "✅ BamOS GNOME theme applied! Logout/login để thấy đầy đủ thay đổi."
    '';
  };
in
{
  # ═══════════════════════════════════════════════════════
  # Theme packages: GTK, Icons, Cursor, GNOME Extensions
  # ═══════════════════════════════════════════════════════
  environment.systemPackages = with pkgs; [
    nordic # GTK/Shell theme (~ OrigamiPaper)
    whitesur-icon-theme # Icons (~ WhiteSur-dark)
    bibata-cursors # Cursors (~ Bibata-Modern-Classic)
    gnomeExtensions.appindicator
    gnomeExtensions.no-overview
    gnomeExtensions.dash-to-dock
    gnomeExtensions.blur-my-shell
    gnomeExtensions.user-themes
    gsettingsActivator # First-login activator
  ];

  # ═══════════════════════════════════════════════════════
  # Fonts: Inter (UI) + Maple Mono NF (monospace)
  # ═══════════════════════════════════════════════════════
  fonts.packages = with pkgs; [
    inter
    maple-mono.NF
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];

  # ═══════════════════════════════════════════════════════
  # System-wide GTK settings.ini — works immediately
  # ═══════════════════════════════════════════════════════
  environment.etc = {
    "gtk-3.0/settings.ini".text = gtkSettings;
    "gtk-4.0/settings.ini".text = gtkSettings;
  };

  # ═══════════════════════════════════════════════════════
  # GNOME apps to exclude (minimalism — RakuOS-inspired)
  # ═══════════════════════════════════════════════════════
  environment.gnome.excludePackages = with pkgs; [
    gnome-console
    epiphany
    geary
    totem
    gedit
    cheese
    gnome-music
    gnome-logs
    gnome-characters
    gnome-tour
    gnome-weather
    gnome-maps
    gnome-clocks
    gnome-contacts
    gnome-calculator
    gnome-calendar
    gnome-user-docs
    xterm
    kitty
    gnome-remote-desktop
    gnome-tour
    gnome-connections
  ];

  # ═══════════════════════════════════════════════════════
  # System dconf — dành cho NEW users (first login)
  # Lưu ý: user đã tồn tại có ~/.config/dconf/user override
  #   → Dùng gsettingsActivator (chạy 1 lần) để force-apply
  # ═══════════════════════════════════════════════════════
  programs.dconf.profiles.user.databases = [{
    settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        gtk-theme = gtkTheme;
        icon-theme = iconTheme;
        cursor-theme = cursorTheme;
        font-name = fontName;
        document-font-name = fontName;
        monospace-font-name = monoFontName;
      };
      "org/gnome/desktop/wm/preferences" = {
        button-layout = "appmenu:minimize,maximize,close";
        mouse-button-modifier = "<Super>";
      };
      "org/gnome/desktop/wm/keybindings" = {
        minimize = [ "<Alt>F9" ];
        maximize = [ "<Alt>F10" ];
        close = [ "<Alt>F4" ];
      };
      "org/gnome/shell" = {
        enabled-extensions = [
          "appindicatorsupport@rgcjonas.gmail.com"
          "dash-to-dock@micxgx.gmail.com"
          "blur-my-shell@aunetx"
          "no-overview@fthx"
          "user-theme@gnome-shell-extensions.gcampax.github.com"
        ];
        favorite-apps = [
          "org.mozilla.firefox.desktop"
          "org.gnome.Nautilus.desktop"
          "org.gnome.Software.desktop"
          "org.gnome.Terminal.desktop"
        ];
      };
      "org/gnome/mutter" = {
        edge-tiling = true;
        dynamic-workspaces = true;
      };
      "org/gnome/settings-daemon/plugins/power" = {
        power-button-action = "suspend";
      };
    };
  }];
}
