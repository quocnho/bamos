# modules/theming/kde-theme.nix
# KDE Plasma theme configuration — RakuOS KDE inspired
#
# RakuOS KDE:
#   Plasma Theme: OrigamiPaper (dark) + OrigamiPaperLight (light)
#   Window Decorations: Aurorae SVG (OrigamiPaperDark/Light)
#   Color Scheme: OrigamiPaperDark.colors, OrigamiPaperLight.colors
#   Kvantum: OrigamiPaper theme (SVG engine)
#   GTK: settings.ini matching theme
#   Font: Inter 11, Maple Mono NF 11
#
# BamOS equivalent (Nord palette):
#   Plasma Theme: Nordic (~ OrigamiPaper)
#   Window Decorations: Nordic (Aurorae)
#   Color Scheme: Nordic Dark
#   Kvantum: Nordic
#   Icons: WhiteSur-dark
#   Cursor: Bibata-Modern-Classic
#   Font: Inter 11, Maple Mono NF 11
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
  # Theme packages: Plasma theme, Kvantum, Icons, Cursors
  # ═══════════════════════════════════════════════════════
  environment.systemPackages = with pkgs; [
    nordic # Plasma theme + Kvantum + Aurorae
    whitesur-icon-theme
    bibata-cursors
    libsForQt5.qtstyleplugins # Qt5 style plugins
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
  # KDE Global Settings (kdeglobals) — colors, fonts, icons
  # ═══════════════════════════════════════════════════════
  environment.etc."xdg/kdeglobals".text = ''
    [KDE]
    ColorScheme=Nordic Dark
    ShowToolbarButton=true
    SingleClick=false

    [General]
    ColorScheme=Nordic Dark
    Name=Nordic Dark
    font=Inter,11,-1,5,50,0,0,0,0,0
    smallestReadableFont=Inter,9,-1,5,50,0,0,0,0,0
    fixed=Maple Mono NF,11,-1,5,50,0,0,0,0,0
    toolBarFont=Inter,11,-1,5,50,0,0,0,0,0
    menuFont=Inter,11,-1,5,50,0,0,0,0,0
    XftAntialias=true
    XftHinting=true
    XftHintStyle=hintfull
    XftRGBA=rgb

    [Icons]
    Theme=${iconTheme}

    [Theme]
    Name=Nordic
    widgetStyle=kvantum

    [WM]
    activeFont=Inter,11,-1,5,50,0,0,0,0,0
    activeForeground=247,250,252
    activeBackground=16,18,22
  '';

  # ═══════════════════════════════════════════════════════
  # KWin window decorations (matching RakuOS Aurorae style)
  # ═══════════════════════════════════════════════════════
  environment.etc."xdg/kwinrc".text = ''
    [org.kde.kdecoration2]
    library=org.kde.kwin.aurorae
    theme=Nordic
    ButtonsOnLeft=M
    ButtonsOnRight=IMX
    BorderSize=Auto
    BorderSizeAuto=true

    [Compositing]
    Enabled=true
    OpenGLIsUnsafe=false
    Backend=OpenGL

    [Windows]
    Placement=Smart
    FocusPolicy=ClickToFocus
    SeparateScreenFocus=false
    ActiveMouseScreen=true
  '';

  # ═══════════════════════════════════════════════════════
  # GTK settings.ini cho KDE apps dùng GTK
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

  # ═══════════════════════════════════════════════════
  # SDDM: Nordic theme cho login screen
  # ═══════════════════════════════════════════════════
  services.displayManager.sddm.theme = "Nordic";
}
