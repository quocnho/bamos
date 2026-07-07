# modules/desktop/software-center.nix
# Software Center theo DE + AppImage management
# - GNOME: GNOME Software | KDE: KDE Discover | COSMIC: Flatpak CLI
# - Gear Lever: GUI AppImage manager (cài, tích hợp menu, update)
# - appimage-run: binfmt support chạy AppImage
# - Flathub + curated apps
#
{ config, pkgs, lib, ... }:

let
  cfg = config.bamos.software-center;
  isKDE = cfg.desktop == "kde";
  isGNOME = cfg.desktop == "gnome";

  curatedApps = [
    "org.mozilla.firefox"
    "org.chromium.Chromium"
    "org.videolan.VLC"
  ];
in
{
  options.bamos.software-center = {
    enable = lib.mkEnableOption "Software Center";

    desktop = lib.mkOption {
      type = lib.types.enum [ "gnome" "kde" "cosmic" ];
      default = "gnome";
      description = "Desktop environment cho Software Center";
    };

    autoAddFlathub = lib.mkEnableOption "Auto-add Flathub" // { default = true; };

    installCuratedApps = lib.mkEnableOption "Install curated Flatpak apps" // { default = false; };

    extraFlatpakApps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra Flatpak apps to install";
      example = [ "org.onlyoffice.desktopeditors" ];
    };
  };

  config = lib.mkIf cfg.enable {
    services.gnome.gnome-software.enable = lib.mkIf isGNOME true;

    environment.systemPackages = with pkgs; (
      (lib.optionals isKDE [ kdePackages.discover ])
      ++ [
        gearlever
        appimage-run
        flatpak
      ]
    );

    services.flatpak.enable = true;

    boot.binfmt.registrations.appimage = {
      wrapInterpreterInShell = true;
      interpreter = "${pkgs.appimage-run}/bin/appimage-run";
      recognitionType = "magic";
      offset = 0;
      mask = "\xff\xff\xff";
      magicOrExtension = "\x41\x49\x02";
    };

    systemd.services.bamos-flathub-setup = lib.mkIf cfg.autoAddFlathub {
      description = "BamOS: Flathub setup + apps";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      path = with pkgs; [ flatpak gnused ];
      script = ''
        flatpak remote-add --if-not-exists flathub \
          https://flathub.org/repo/flathub.flatpakrepo

        ${lib.optionalString cfg.installCuratedApps (lib.concatStringsSep "\n" (map (app: ''
          if ! flatpak info "${app}" &>/dev/null; then
            echo "Installing: ${app}"
            flatpak install --noninteractive --assumeyes flathub "${app}" 2>/dev/null || true
          fi
        '') curatedApps))}

        ${lib.concatStringsSep "\n" (map (app: ''
          if ! flatpak info "${app}" &>/dev/null; then
            echo "Installing: ${app}"
            flatpak install --noninteractive --assumeyes flathub "${app}" 2>/dev/null || true
          fi
        '') cfg.extraFlatpakApps)}
      '';
      serviceConfig.Type = "oneshot";
    };
  };
}
