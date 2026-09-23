# Description: GNOME Software + Flatpak backend và tích hợp theme (cho end-user)
{ config, lib, pkgs, ... }:

let
  cfg = config.my.gnome;
  localFonts = pkgs.callPackage ../../assets/fonts/fonts.nix { };
in
{
  config = lib.mkIf (cfg.enable && cfg.store) {
    services.gnome.gnome-software.enable = true;
    services.flatpak.enable = true;

    # Kho Flathub cho GNOME Software
    systemd.services.flatpak-add-flathub = {
      wantedBy = [ "multi-user.target" ];
      requires = [ "network-online.target" ];
      after = [ "network-online.target" ];
      path = [ pkgs.flatpak ];
      script = ''
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
      '';
    };

    # Môi trường tích hợp: cấp quyền truy cập theme & fonts cho Flatpak apps
    systemd.user.services.flatpak-system-integration = {
      wantedBy = [ "default.target" ];
      path = [ pkgs.flatpak ];
      script = ''
        flatpak override --user --filesystem=xdg-config/gtk-3.0:ro
        flatpak override --user --filesystem=xdg-config/gtk-4.0:ro

        mkdir -p "$HOME/.local/share/fonts"
        cp -rn ${localFonts}/share/fonts/truetype/. "$HOME/.local/share/fonts/" 2>/dev/null || true
      '';
    };
  };
}
