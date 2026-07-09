# modules/core/third-party.nix
# Third-party application runtime support
# Các thư viện và công cụ cần thiết để chạy ứng dụng bên thứ 3
#
# Phân tích từ Ventoy và các distro hiện đại:
#   1. AppImage runtime: FUSE, appimage-run
#   2. Flatpak runtime: flatpak, xdg-desktop-portal
#   3. Container runtime: Podman/Docker, Distrobox
#   4. Windows apps: Wine (optional, per edition)
#   5. Android apps: Waydroid (optional, per edition)
#   6. Gaming: Steam runtime, GameScope, MangoHud
#   7. Multimedia codecs: ffmpeg, gstreamer, va-api
#   8. Fonts: Noto, Liberation, CJK, emoji
#   9. Archive support: p7zip, unrar, unzip, file-roller
#  10. Network tools: curl, wget, networkmanager
#  11. Development: git, gcc, make, cmake, python
#  12. System tools: polkit, udisks, upower, dbus
#
{ pkgs, lib, config, ... }:

let
  cfg = config.bamos.third-party;
  isKDE = config.services.desktopManager.plasma6.enable or false;
in
{
  options.bamos.third-party = {
    appimage = lib.mkEnableOption "AppImage support" // { default = true; };
    flatpak = lib.mkEnableOption "Flatpak support" // { default = true; };
    container = lib.mkEnableOption "Container runtime (Podman)" // { default = true; };
    distrobox = lib.mkEnableOption "Distrobox containers" // { default = true; };
    fhs-compat = lib.mkEnableOption "FHS compatibility (steam-run-like)" // { default = true; };
    wine = lib.mkEnableOption "Wine Windows compatibility" // { default = false; };
    waydroid = lib.mkEnableOption "Waydroid Android support" // { default = false; };
    codecs = lib.mkEnableOption "Multimedia codecs" // { default = true; };
    fonts = lib.mkEnableOption "Extra fonts" // { default = true; };
    archive = lib.mkEnableOption "Archive tools" // { default = true; };
    network = lib.mkEnableOption "Network tools" // { default = true; };
  };

  config = lib.mkMerge [
    # ═══════════════════════════════════════════════════════
    # FHS Compatibility — chạy binary Linux tiền biên dịch
    # (Ventoy, MATLAB, Cisco VPN, Zoom .deb, v.v.)
    # Cung cấp lệnh bam run thay thế bamos-fhs
    # ═══════════════════════════════════════════════════════
    (lib.mkIf cfg.fhs-compat {
      environment.systemPackages = with pkgs; [ bam-cli ];
    })

    # ═══════════════════════════════════════════════════════
    # AppImage Runtime
    # ═══════════════════════════════════════════════════════
    (lib.mkIf cfg.appimage {
      boot.binfmt.registrations.appimage = {
        wrapInterpreterInShell = true;
        interpreter = "${pkgs.appimage-run}/bin/appimage-run";
        recognitionType = "magic";
        offset = 0;
        mask = "\xff\xff\xff";
        magicOrExtension = "\x41\x49\x02";
      };
      environment.systemPackages = with pkgs; [
        appimage-run
        gearlever # AppImage GUI manager
        fuse3
      ];
    })

    # ═══════════════════════════════════════════════════════
    # Flatpak Runtime
    # ═══════════════════════════════════════════════════════
    (lib.mkIf cfg.flatpak {
      services.flatpak.enable = true;
      environment.systemPackages = with pkgs; [ flatpak ];

      # XDG Desktop Portal cho Flatpak integration
      xdg.portal = {
        enable = true;
        wlr.enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-gtk
        ] ++ lib.optionals isKDE [
          kdePackages.xdg-desktop-portal-kde
        ];
      };
    })

    # ═══════════════════════════════════════════════════════
    # Container Runtime (Podman)
    # ═══════════════════════════════════════════════════════
    (lib.mkIf cfg.container {
      virtualisation.podman = {
        enable = true;
        dockerCompat = true;
        defaultNetwork.settings.dns_enabled = true;
      };
      environment.systemPackages = with pkgs; [ podman-compose ];
    })

    # ═══════════════════════════════════════════════════════
    # Distrobox
    # ═══════════════════════════════════════════════════════
    (lib.mkIf cfg.distrobox {
      environment.systemPackages = with pkgs; [ distrobox ];
    })

    # ═══════════════════════════════════════════════════════
    # Wine (Windows compatibility)
    # ═══════════════════════════════════════════════════════
    (lib.mkIf cfg.wine {
      environment.systemPackages = with pkgs; [
        wineWowPackages.waylandFull
        winetricks
        protontricks
      ];
    })

    # ═══════════════════════════════════════════════════════
    # Waydroid (Android)
    # ═══════════════════════════════════════════════════════
    (lib.mkIf cfg.waydroid {
      virtualisation.waydroid.enable = true;
      environment.systemPackages = with pkgs; [ waydroid ];
    })

    # ═══════════════════════════════════════════════════════
    # Multimedia Codecs
    # ═══════════════════════════════════════════════════════
    (lib.mkIf cfg.codecs {
      environment.systemPackages = with pkgs; [
        ffmpeg
        gst_all_1.gstreamer
        gst_all_1.gst-plugins-base
        gst_all_1.gst-plugins-good
        gst_all_1.gst-plugins-bad
        gst_all_1.gst-plugins-ugly
        gst_all_1.gst-libav
        libva
        libva-utils
        nvidia-vaapi-driver
      ];
      # Hardware video acceleration
      hardware.graphics = {
        enable = true;
        extraPackages = with pkgs; [
          intel-media-driver
          intel-vaapi-driver
          libva-vdpau-driver
          libvdpau-va-gl
        ];
      };
    })

    # ═══════════════════════════════════════════════════════
    # Extra Fonts
    # ═══════════════════════════════════════════════════════
    (lib.mkIf cfg.fonts {
      fonts.packages = with pkgs; [
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        noto-fonts-color-emoji
        liberation_ttf
        dejavu_fonts
        inter
        maple-mono.NF
      ];
    })

    # ═══════════════════════════════════════════════════════
    # Archive Tools
    # ═══════════════════════════════════════════════════════
    (lib.mkIf cfg.archive {
      environment.systemPackages = with pkgs; [
        file-roller # GUI archive manager
        p7zip
        unzip
        unrar
        bzip2
        xz
        zstd
        gnome-autoar # GNOME archive integration
      ];
    })

    # ═══════════════════════════════════════════════════════
    # Network Tools
    # ═══════════════════════════════════════════════════════
    (lib.mkIf cfg.network {
      environment.systemPackages = with pkgs; [
        curl
        wget
        openssl
        gnupg
        iperf3
        nmap
        traceroute
        mtr
        wireguard-tools
        openvpn
      ];
    })
  ];
}
