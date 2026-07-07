# modules/software-center.nix
# Software Center theo DE + AppImage management
#
# WPS Office Flatpak:
#   com.wps.Office   — WPS Office 11 (Qt 5.12, lỗi DPI asymmetric)
#   cn.wps.wps_365   — WPS 365 v12 (Qt mới hơn, KHÔNG lỗi DPI)
#
# ✅ Khuyến nghị: dùng cn.wps.wps_365 (DPI + fonts ổn định hơn)
#
# Fonts trên NixOS:
#   Fonts chỉ có trong Nix store, Flatpak sandbox không thấy.
#   → Symlink fonts → ~/.local/share/fonts/wps-365/
#   → Flatpak có sẵn access đến ~/.local/share/fonts/
#
{ config, pkgs, lib, ... }:

let
  cfg = config.bamos.software-center;
  isKDE = cfg.desktop == "kde";
  isGNOME = cfg.desktop == "gnome";

  # WPS app ID (mặc định WPS 365 v12)
  wpsAppId = "cn.wps.wps_365";
  hasWPS = builtins.elem wpsAppId cfg.extraFlatpakApps;

  # Danh sách Flatpak apps cài sẵn
  curatedApps = [
    "org.mozilla.firefox"
    "org.chromium.Chromium"
    "org.videolan.VLC"
  ];

  # Fonts cần cho WPS (CJK + Symbol + Metric MS)
  wpsFonts = with pkgs; [
    noto-fonts-cjk-sans # Chinese sans (宋体, 黑体)
    noto-fonts-cjk-serif # Chinese serif (SimSun)
    unifont # Wingdings/Webdings/Symbol glyphs
    liberation_ttf # Metric MS fonts (Arial, Times, Courier)
    dejavu_fonts # General fallback
  ];

  # ═══════════════════════════════════════════════════════
  # Script: symlink fonts → ~/.local/share/fonts/wps-365/
  # Flatpak có sẵn access đến ~/.local/share/fonts/
  # ═══════════════════════════════════════════════════════
  wpsFontSymlinkScript = pkgs.writeShellApplication {
    name = "bamos-wps-font-symlink";
    runtimeInputs = with pkgs; [ coreutils gnused fontconfig ];
    text = ''
      set -euo pipefail

      FONT_DST="${"$"}{XDG_DATA_HOME:-$HOME/.local/share}/fonts/wps-365"
      mkdir -p "$FONT_DST"

      echo "📄 BamOS: Symlinking fonts for WPS 365..."

      # Font sources from Nix store
      FONT_SOURCES="${lib.concatStringsSep "\n" (map (pkg: ''
        ${pkg}/share/fonts
      '') wpsFonts)}"

      count=0
      while IFS= read -r src_dir; do
        if [ -d "$src_dir" ]; then
          find "$src_dir" -type f \( -name "*.ttf" -o -name "*.otf" -o -name "*.ttc" \) | while read -r font_file; do
            fname=$(basename "$font_file")
            target="$FONT_DST/$fname"
            if [ ! -e "$target" ]; then
              ln -sf "$font_file" "$target"
              echo "  → $fname"
              count=$((count + 1))
            fi
          done
        fi
      done <<< "$FONT_SOURCES"

      # Update fontconfig cache
      fc-cache -f "$FONT_DST" 2>/dev/null || true

      echo "✅ WPS 365 fonts symlinked ($count files) to $FONT_DST"
    '';
  };

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
      description = "Extra Flatpak apps to install. Ex: [ \"cn.wps.wps_365\" ]";
      example = [ "cn.wps.wps_365" ];
    };

    wpsFix = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Bật font + DPI fix cho WPS Office Flatpak.
        Fonts: symlink CJK + Symbol fonts vào ~/.local/share/fonts/wps-365/
        DPI: Qt env vars cho WPS 365 (v12+ không cần, để dự phòng)
        App: cn.wps.wps_365 (WPS 365 v12 — khuyến nghị)
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # DE-specific Software Center
    services.gnome.gnome-software.enable = lib.mkIf isGNOME true;

    environment.systemPackages = with pkgs; (
      (lib.optionals isKDE [ kdePackages.discover ])
      ++ [
        gearlever # AppImage GUI
        appimage-run # AppImage runner
        flatpak # Flatpak CLI
      ]
      ++ lib.optionals (hasWPS && cfg.wpsFix) [
        wpsFontSymlinkScript
      ]
    );

    # Host fonts cho WPS 365
    fonts.packages = lib.mkIf (hasWPS && cfg.wpsFix) wpsFonts;

    # Flatpak
    services.flatpak.enable = true;

    # AppImage binfmt (format 1 + 2)
    boot.binfmt.registrations.appimage = {
      wrapInterpreterInShell = true;
      interpreter = "${pkgs.appimage-run}/bin/appimage-run";
      recognitionType = "magic";
      offset = 0;
      mask = "\xff\xff\xff";
      magicOrExtension = "\x41\x49\x02";
    };

    # Systemd user service: symlink WPS fonts ở mỗi login
    systemd.user.services.bamos-wps-font-symlink = lib.mkIf (hasWPS && cfg.wpsFix) {
      description = "BamOS: WPS 365 font symlinks";
      wantedBy = [ "default.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${wpsFontSymlinkScript}/bin/bamos-wps-font-symlink";
        RemainAfterExit = true;
      };
    };

    # ═══════════════════════════════════════════════════════
    # Flathub setup + apps install + WPS override
    # ═══════════════════════════════════════════════════════
    systemd.services.bamos-flathub-setup = lib.mkIf cfg.autoAddFlathub {
      description = "BamOS: Flathub setup + apps + WPS 365 override";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      path = with pkgs; [ flatpak gnused ];
      script = ''
        # Thêm Flathub remote
        flatpak remote-add --if-not-exists flathub \
          https://flathub.org/repo/flathub.flatpakrepo

        # Cài đặt curated apps + extra apps (WPS 365)
        ALL_APPS="${lib.concatStringsSep " " (curatedApps ++ cfg.extraFlatpakApps)}"
        for app in $ALL_APPS; do
          if ! flatpak info "$app" &>/dev/null; then
            echo "Installing: $app"
            flatpak install --noninteractive --assumeyes flathub "$app" 2>/dev/null || true
          fi
        done

        # ═══════════════════════════════════════════════════
        # WPS 365 Flatpak override (fonts + DPI dự phòng)
        # ═══════════════════════════════════════════════════
        ${lib.optionalString (hasWPS && cfg.wpsFix) ''
          if flatpak info ${wpsAppId} &>/dev/null; then
            echo "Configuring WPS 365 (fonts + DPI)..."
            flatpak override ${wpsAppId} \
              --filesystem=xdg-data/fonts:ro \
              --filesystem=xdg-config/fontconfig:ro \
              --env=QT_AUTO_SCREEN_SCALE_FACTOR=0 \
              --env=QT_SCALE_FACTOR=1 \
              --env=QT_ENABLE_HIGHDPI_SCALING=0
            echo "  ✅ WPS 365 configured!"
            echo "  ├─ Fonts: ~/.local/share/fonts/ (xdg-data/fonts)"
            echo "  ├─ QT_AUTO_SCREEN_SCALE_FACTOR=0"
            echo "  ├─ QT_SCALE_FACTOR=1"
            echo "  └─ QT_ENABLE_HIGHDPI_SCALING=0"
          fi
        ''}
      '';
      serviceConfig.Type = "oneshot";
    };
  };
}
