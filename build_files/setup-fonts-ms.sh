#!/usr/bin/env bash
# setup-fonts-ms — Install Microsoft Core Fonts via cabextract
# Downloads and installs: Times New Roman, Arial, Courier New, etc.
# This uses the standard Andale/Core fonts method
#
# Usage:
#   bamos setup-fonts-ms

set -euo pipefail

FONT_DIR="$HOME/.local/share/fonts/microsoft"
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

echo "============================================="
echo "  Microsoft Core Fonts Installer"
echo "============================================="
echo ""

# Check for cabextract
if ! command -v cabextract &>/dev/null; then
    echo "Installing cabextract..."
    sudo rpm-ostree install cabextract || {
        echo "Cannot install cabextract. Please install manually:"
        echo "  sudo dnf install cabextract"
        exit 1
    }
    echo "Reboot required. Run this script again after reboot."
    exit 0
fi

mkdir -p "$FONT_DIR"
cd "$TEMP_DIR"

# Microsoft Core Fonts — using the standard source
MS_FONTS_URL="https://downloads.sourceforge.net/project/corefonts/the%20fonts/final"

declare -A FONTS=(
    ["andale32.exe"]="Andale Mono"
    ["arial32.exe"]="Arial"
    ["arialb32.exe"]="Arial Bold"
    ["comic32.exe"]="Comic Sans MS"
    ["courie32.exe"]="Courier New"
    ["georgi32.exe"]="Georgia"
    ["impact32.exe"]="Impact"
    ["times32.exe"]="Times New Roman"
    ["trebuc32.exe"]="Trebuchet MS"
    ["verdan32.exe"]="Verdana"
    ["webdin32.exe"]="Webdings"
)

echo "Downloading and extracting Microsoft Core Fonts..."
INSTALLED=0

for exe in "${!FONTS[@]}"; do
    name="${FONTS[$exe]}"
    echo -n "  $name... "

    if curl -fsSL "${MS_FONTS_URL}/${exe}" -o "${exe}" 2>/dev/null; then
        cabextract -q -d "$FONT_DIR" "${exe}" 2>/dev/null && {
            echo "✓"
            INSTALLED=$((INSTALLED + 1))
        } || echo "✗ (extract failed)"
    else
        echo "✗ (download failed)"
    fi
done

# Clean up extracted non-font files
find "$FONT_DIR" -type f ! -name "*.ttf" ! -name "*.TTF" -delete 2>/dev/null || true

echo ""
echo "Updating font cache..."
fc-cache -fv

echo ""
echo "============================================="
echo "  Installed $INSTALLED Microsoft fonts!"
echo "============================================="
echo ""
echo "Font location: $FONT_DIR"
echo "Restart applications to use new fonts."
echo ""
echo "Note: These fonts are provided under Microsoft's"
echo "End User License Agreement. Review terms at:"
echo "https://www.microsoft.com/typography/fonts/"
