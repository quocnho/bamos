# modules/theming/cosmic-theme.nix
# COSMIC DE theme configuration — RakuOS COSMIC inspired
#
# RakuOS COSMIC:
#   Theme: OrigamiPaper (Nord palette)
#   Font: Inter 11, Maple Mono NF 11
#   Icons: WhiteSur-dark
#
# BamOS equivalent:
#   Theme: Nordic
#   Font: Inter 11, Maple Mono NF 11
#   Icons: WhiteSur-dark
#   Cursor: Bibata-Modern-Classic
#
{ pkgs, lib, ... }:

let
  gtkTheme = "Nordic";
  iconTheme = "WhiteSur-dark";
  cursorTheme = "Bibata-Modern-Classic";
  fontName = "Inter 11";
  monoFontName = "Maple Mono NF 11";
in
{
  # ═══════════════════════════════════════════════════════
  # Theme packages: GTK, Icons, Cursor
  # ═══════════════════════════════════════════════════════
  environment.systemPackages = with pkgs; [
    nordic
    whitesur-icon-theme
    bibata-cursors
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
  # System-wide GTK settings.ini
  # ═══════════════════════════════════════════════════════
  environment.etc."gtk-3.0/settings.ini".text = ''
    [Settings]
    gtk-theme-name=${gtkTheme}
    gtk-icon-theme-name=${iconTheme}
    gtk-cursor-theme-name=${cursorTheme}
    gtk-font-name=${fontName}
    gtk-monospace-font-name=${monoFontName}
    gtk-application-prefer-dark-theme=1
    gtk-error-bell=0
  '';

  environment.etc."gtk-4.0/settings.ini".text = ''
    [Settings]
    gtk-theme-name=${gtkTheme}
    gtk-icon-theme-name=${iconTheme}
    gtk-cursor-theme-name=${cursorTheme}
    gtk-font-name=${fontName}
    gtk-monospace-font-name=${monoFontName}
    gtk-application-prefer-dark-theme=1
  '';

  # ═══════════════════════════════════════════════════════
  # COSMIC dconf settings
  # ═══════════════════════════════════════════════════════
  programs.dconf.profiles.user.databases = [{
    settings = {
      "org/gnome/desktop/interface" = {
        gtk-theme = gtkTheme;
        icon-theme = iconTheme;
        cursor-theme = cursorTheme;
        font-name = fontName;
        document-font-name = fontName;
        monospace-font-name = monoFontName;
      };
      "org/gnome/desktop/wm/preferences" = {
        button-layout = "appmenu:minimize,maximize,close";
      };
      "com/system76/CosmicTheme" = {
        name = "dark";
        accent = "#81A1C1";
      };
    };
  }];
}
