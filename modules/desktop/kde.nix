# modules/desktop/kde.nix
# KDE Plasma 6 Desktop Environment + SDDM display manager
# Wayland-native, highly customizable
{ lib
, pkgs
, ...
}:

{
  imports = [
    ../theming/kde-theme.nix
  ];

  # SDDM display manager (thay GDM)
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # KDE Plasma 6
  services.desktopManager.plasma6.enable = true;

  # Keyboard layout
  services.xserver.xkb.layout = "us";

  # Tắt bloatware
  services.displayManager.sddm.autoNumlock = lib.mkDefault true;

  # ═══════════════════════════════════════════════════════
  # Window buttons: Min / Max / Close
  # KDE Plasma 6 mặc định đã có cả 3 nút minimize □, maximize □, close ✕
  # Cấu hình skeleton để đảm bảo user mới có đúng layout
  # ═══════════════════════════════════════════════════════
  environment.etc = {
    "skel/.config/kwinrc" = {
      text = ''
        [org.kde.kdecoration2]
        ButtonsOnLeft=M
        ButtonsOnRight=IMX
      '';
    };

    # ═══════════════════════════════════════════════════
    # Dolphin sidebar: Ổ D (/data) bookmark
    # ═══════════════════════════════════════════════════
    "skel/.config/dolphinrc" = {
      text = ''
        [Places]
        PlacesCount=2
        Place0[Url]=file:///data
        Place0[Name]=Ổ D (DATA)
        Place1[Url]=file:///home
        Place1[Name]=Home
      '';
    };
  };
}
