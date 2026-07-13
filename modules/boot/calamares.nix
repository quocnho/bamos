# modules/boot/calamares.nix
# Calamares installer — Unified Installer + Ổ C — Ổ D + Branding
#
# ═══════════════════════════════════════════════════════════════
# Tích hợp:
#   1. Partition: Btrfs Ổ C — Ổ D  (EFI + @ + @home + @nix + @data)
#   2. Edition selection: Standard/Developers/Gaming/Studio
#   3. Machine type: Laptop/Desktop/Server
#   4. Ổ D icon + Nautilus bookmark (custom drive icon)
#   5. Branding: logo, images, fonts (GLF-OS inspired)
#   6. /iso-cfg: post-install flake template cho updates
# ═══════════════════════════════════════════════════════════════
#
# Calamares config:
#   - Package calamares-nixos-extensions (override via overlay) chứa settings.conf
#   - Module configs (partition.conf, mount.conf, packagechooser-*.conf) cũng
#     được override trong package để tránh issues với XDG_CONFIG_DIRS
#   - Custom Python module bamos-config → /etc/calamares/modules/bamos-config/

{ config, lib, pkgs, ... }: with lib;

let
  # ═══════════════════════════════════════════════════════
  # Ổ D icon — giống biểu tượng ổ đĩa Windows (D:)
  # Tự động thêm vào Nautilus sidebar sau cài đặt
  # ═══════════════════════════════════════════════════════
  dataDriveIcon = pkgs.runCommand "data-drive-icon"
    {
      nativeBuildInputs = [ pkgs.librsvg ];
      preferLocalBuild = true;
    } ''
    mkdir -p $out/share/icons/hicolor/scalable/emblems
    mkdir -p $out/share/icons/hicolor/48x48/emblems

    # SVG icon — ổ D với nhãn DATA
    cat > $out/share/icons/hicolor/scalable/emblems/drive-data.svg << 'SVGEOF'
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
      <rect x="4" y="12" width="40" height="28" rx="3" fill="#4A90D9" stroke="#2C5F8A" stroke-width="2"/>
      <rect x="8" y="16" width="32" height="20" rx="2" fill="#E8F0FE"/>
      <text x="24" y="31" font-family="sans-serif" font-size="16" font-weight="bold" fill="#2C5F8A" text-anchor="middle">DATA</text>
    </svg>
    SVGEOF

    # PNG icon 48x48 từ SVG (with bootstrap fallback)
    if command -v rsvg-convert >/dev/null 2>&1; then
      rsvg-convert -w 48 -h 48 \
        $out/share/icons/hicolor/scalable/emblems/drive-data.svg \
        -o $out/share/icons/hicolor/48x48/emblems/drive-data.png
      echo "rsvg-convert: PNG icon created successfully"
    else
      echo "WARNING: rsvg-convert not found — using SVG as fallback"
      ln -sf \
        $out/share/icons/hicolor/scalable/emblems/drive-data.svg \
        $out/share/icons/hicolor/48x48/emblems/drive-data.png
    fi
  '';

  # ═══════════════════════════════════════════════════════
  # Calamares branding assets (GLF-OS inspired)
  # ═══════════════════════════════════════════════════════
  calamaresBranding = pkgs.runCommand "calamares-bamos-branding"
    {
      nativeBuildInputs = [ pkgs.librsvg ];
    } ''
    mkdir -p $out/share/calamares/branding/bamos/images

    # ── Logo (SVG) — copy từ assets/logo/bamos-logo.svg ──
    cp ${../../assets/logo/bamos-logo.svg} $out/share/calamares/branding/bamos/images/bamos-logo.svg
    cp ${../../assets/logo/bamos-logo-nav.svg} $out/share/calamares/branding/bamos/images/bamos-logo-nav.svg

    # ── Logo PNG — convert từ SVG ──
    if command -v rsvg-convert >/dev/null 2>&1; then
      rsvg-convert -w 128 -h 128 \
        $out/share/calamares/branding/bamos/images/bamos-logo.svg \
        -o $out/share/calamares/branding/bamos/images/bamos-logo.png
    else
      # Fallback: symlink SVG as PNG
      cp $out/share/calamares/branding/bamos/images/bamos-logo.svg \
         $out/share/calamares/branding/bamos/images/bamos-logo.png
    fi

    # ── Edition screenshots (placeholders) ──
    for img in standard developers gaming studio laptop desktop server; do
      # Tạo SVG screenshot placeholder
      cat > $out/share/calamares/branding/bamos/images/$img.svg << SCREENSHOT
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 150">
      <rect width="200" height="150" fill="#f0f0f0" rx="8"/>
      <rect x="10" y="10" width="180" height="20" rx="4" fill="#4CAF50"/>
      <text x="100" y="25" font-family="sans-serif" font-size="10" fill="white" text-anchor="middle">$img</text>
      <rect x="10" y="40" width="180" height="100" rx="4" fill="#e0e0e0"/>
      <text x="100" y="90" font-family="sans-serif" font-size="14" fill="#666" text-anchor="middle">$img</text>
    </svg>
    SCREENSHOT

      # Convert to PNG via rsvg-convert nếu có
      if command -v rsvg-convert >/dev/null 2>&1; then
        rsvg-convert -w 200 -h 150 \
          $out/share/calamares/branding/bamos/images/$img.svg \
          -o $out/share/calamares/branding/bamos/images/$img.png
      else
        cp $out/share/calamares/branding/bamos/images/$img.svg \
           $out/share/calamares/branding/bamos/images/$img.png
      fi
    done

    # ── Branding description ──
    cat > $out/share/calamares/branding/bamos/branding.desc << 'BRANDING'
    ---
    componentName: bamos
    name: BamOS
    version: 4.0.0
    short: BamOS Installer
    shortVersion: 4.0
    long: BamOS — NixOS Distribution for the Vietnamese Community
    longVersion: 4.0.0
    supportsNonFree: true
    website: https://bamos.io
    image: "bamos-logo.png"
    imageSize: 128
    imageWidth: 128
    imageHeight: 128
    productIcon: "bamos-logo.svg"
    slideshow: "slideshow.qml"
    style:
      sidebar:
        backgroundColor: "#2E7D32"
        textColor: "#FFFFFF"
        selectedBackgroundColor: "#4CAF50"
        selectedTextColor: "#FFFFFF"
    translations:
      vi: "BamOS — Bản phân phối NixOS cho người Việt"
    BRANDING

    # ── QML Slideshow ──
    cat > $out/share/calamares/branding/bamos/slideshow.qml << 'SLIDESHOW'
    import QtQuick 2.15
    import QtQuick.Controls 2.15

    Presentation {
      id: presentation
      Slide {
        title: qsTr("Welcome to BamOS")
        content: qsTr("NixOS Distribution for the Vietnamese Community")
      }
      Slide {
        title: qsTr("Features")
        content: qsTr("- Vietnamese input OOTB\n- Btrfs snapshot engine\n- Auto hardware detection\n- Gaming optimized")
      }
      Slide {
        title: qsTr("Get Started")
        content: qsTr("Select your preferred Edition and Machine Type in the next steps.")
      }
    }
    SLIDESHOW
  '';

  # ═══════════════════════════════════════════════════════
  # Custom Calamares Python module: bamos-config
  # Sinh edition-config.nix + /iso-cfg để người dùng update sau
  # ═══════════════════════════════════════════════════════
  # bamos-config Python module đã được chuyển vào overlay (overlays/default.nix)
  # và bundle trong calamares-nixos-extensions (override qua symlinkJoin)

in
{
  # ── Wayland environment cho Calamares (fix DPI nhỏ / font nhỏ) ──
  # Kết hợp với autostart fix trong calamares-overlay.nix (sudo --preserve-env)
  # Dùng mkForce để ghi đè giá trị từ installation-cd-graphical-calamares-gnome.nix
  environment.variables = {
    # Qt Wayland: ưu tiên wayland, fallback xcb
    # Dùng mkForce để ghi đè giá trị shell từ installation-cd-graphical-calamares-gnome.nix
    QT_QPA_PLATFORM = lib.mkForce "wayland;xcb";
    # Tự động scale trên màn hình HiDPI
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    # GTK backend (cho file dialogs)
    GDK_BACKEND = "wayland,x11";
  };

  # ── Calamares branding & data drive icon ──
  # bamos-config Python module đã bundle trong calamares-nixos-extensions (overlay)
  environment.systemPackages = with pkgs; [
    calamaresBranding
    dataDriveIcon
  ];

  # ── Expose iso-cfg template to ISO live environment ──
  # Calamares Python module sẽ copy từ đây vào /etc/nixos/ khi cài đặt
  environment.etc."nixos-template/flake.nix".source = ../../iso-cfg/flake.nix;
  environment.etc."nixos-template/configuration.nix".source = ../../iso-cfg/configuration.nix;
  environment.etc."nixos-template/customized.nix".source = ../../iso-cfg/customized.nix;
  environment.etc."nixos-template/customConfig/default.nix".source = ../../iso-cfg/customConfig/default.nix;
}
