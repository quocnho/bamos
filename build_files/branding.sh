#!/bin/bash
# bamos-branding.sh — Apply BamOS branding to the system
# Sets logo, Plymouth theme, GRUB, OS release, fastfetch, wallpapers

set -euo pipefail

echo "[bamos] Applying branding..."

BRANDING_SRC="/usr/share/bamos/branding"
LOGO_SVG="${BRANDING_SRC}/logo-bamos.svg"

# =============================================================================
# 1. Plymouth Boot Theme
# =============================================================================

if [[ -d /usr/share/plymouth/themes/bamos ]]; then
    echo "[bamos] Setting Plymouth theme..."
    plymouth-set-default-theme bamos -R 2>/dev/null || true
fi

# =============================================================================
# 2. Desktop Logo & Icons
# =============================================================================

if [[ -f "$LOGO_SVG" ]]; then
    # Copy to standard pixmaps location
    cp "$LOGO_SVG" /usr/share/pixmaps/bamos-logo.svg 2>/dev/null || true

    # Convert to various sizes for system icons
    if command -v rsvg-convert &>/dev/null; then
        for size in 16 24 32 48 64 128 256; do
            rsvg-convert -w "$size" -h "$size" \
                "$LOGO_SVG" \
                -o "/usr/share/icons/hicolor/${size}x${size}/apps/bamos-logo.png" 2>/dev/null || true
        done
        # Update icon cache
        gtk-update-icon-cache -f -t /usr/share/icons/hicolor 2>/dev/null || true
    fi
fi

# =============================================================================
# 3. GRUB Theme & Background
# =============================================================================

if [[ -f "${BRANDING_SRC}/grub-background.png" ]]; then
    mkdir -p /boot/grub2/themes/bamos
    cp "${BRANDING_SRC}/grub-background.png" /boot/grub2/themes/bamos/background.png 2>/dev/null || true
fi

# =============================================================================
# 4. OS Release Information
# =============================================================================

if [[ -f "${BRANDING_SRC}/os-release" ]]; then
    # Append BamOS info to os-release (don't overwrite Fedora base)
    cp "${BRANDING_SRC}/os-release" /usr/lib/bamos-release 2>/dev/null || true

    # Update /etc/system-release symlink
    if [[ -f "${BRANDING_SRC}/system-release" ]]; then
        cp "${BRANDING_SRC}/system-release" /etc/system-release 2>/dev/null || true
    fi
fi

# =============================================================================
# 5. ISO/USB Live Branding
# =============================================================================

# Copy GRUB config for ISO generation
if [[ -f "${BRANDING_SRC}/iso-grub.cfg" ]]; then
    mkdir -p /usr/share/bamos
    cp "${BRANDING_SRC}/iso-grub.cfg" /usr/share/bamos/iso-grub.cfg 2>/dev/null || true
fi

# Live environment os-release
if [[ -f "${BRANDING_SRC}/live-os-release" ]]; then
    cp "${BRANDING_SRC}/live-os-release" /usr/share/bamos/live-os-release 2>/dev/null || true
fi

# =============================================================================
# 6. Backgrounds / Wallpapers
# =============================================================================

mkdir -p /usr/share/backgrounds/bamos
mkdir -p /usr/share/gnome-background-properties

# Copy wallpaper if available
if [[ -f "${BRANDING_SRC}/wallpaper.png" ]]; then
    cp "${BRANDING_SRC}/wallpaper.png" /usr/share/backgrounds/bamos/default.png 2>/dev/null || true
fi

# Create GNOME background XML descriptor
cat > /usr/share/gnome-background-properties/bamos.xml <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE wallpapers SYSTEM "gnome-wp-list.dtd">
<wallpapers>
  <wallpaper deleted="false">
    <name>BamOS</name>
    <filename>/usr/share/backgrounds/bamos/default.png</filename>
    <options>zoom</options>
    <pcolor>#1a5c32</pcolor>
    <scolor>#0d3319</scolor>
    <shade_type>solid</shade_type>
  </wallpaper>
</wallpapers>
XML

# =============================================================================
# 7. Fastfetch Branding Config
# =============================================================================

mkdir -p /usr/share/fastfetch/presets/bamos

cat > /usr/share/fastfetch/presets/bamos/bamos-fastfetch.jsonc <<'JSON'
{
    "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
    "logo": {
        "type": "small",
        "source": "/usr/share/pixmaps/bamos-logo.png"
    },
    "display": {
        "separator": " → ",
        "key": {
            "width": 14
        }
    },
    "modules": [
        {
            "type": "title",
            "key": "🐉 BamOS",
            "format": "{user-name}@{host-name}"
        },
        { "type": "os" },
        { "type": "kernel" },
        { "type": "packages" },
        { "type": "shell" },
        { "type": "wm" },
        { "type": "terminal" },
        { "type": "cpu" },
        { "type": "gpu" },
        { "type": "memory" },
        { "type": "disk" }
    ]
}
JSON

echo "[bamos] Branding applied."
