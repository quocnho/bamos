# modules/desktop/cosmic.nix
# COSMIC Desktop Environment — Rust-based DE by System76
{ lib
, pkgs
, ...
}:

{
  imports = [
    ../theming/cosmic-theme.nix
  ];

  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;

  # ═══════════════════════════════════════════════════════
  # Window buttons: Min / Max / Close
  # COSMIC mặc định dùng COSMIC Settings (dconf-based)
  # ═══════════════════════════════════════════════════════
  programs.dconf.profiles.user.databases = [{
    settings = {
      "com/system76/CosmicApplet" = {
        "windows" = true;
      };
    };
  }];
}
