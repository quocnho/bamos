#!/usr/bin/env bash
# fetch-assets.sh — Download BamOS theme assets for offline use
# Run: ./assets/fetch-assets.sh
# Downloads themes, icons, fonts, cursors into assets/ subdirectories
#
# RakuOS-inspired theme stack:
#   GTK Theme:  Nordic (~ OrigamiPaper)
#   Icons:      WhiteSur-dark
#   Cursor:     Bibata-Modern-Classic
#   Fonts:      Inter + Maple Mono NF
#
set -euo pipefail
cd "$(dirname "$0")"

echo "============================================"
echo "  Downloading BamOS theme assets"
echo "  (RakuOS-inspired: Nordic + WhiteSur + Bibata)"
echo "============================================"

# ── URLs ────────────────────────────────────────────────────
# GTK Theme: Nordic (matches OrigamiPaper Nord palette)
NORDIC_URL="https://github.com/EliverLara/Nordic/releases/download/v2.2.0/Nordic.tar.xz"

# Icon Theme: WhiteSur-dark
WHITESUR_URL="https://github.com/vinceliuice/WhiteSur-icon-theme/archive/refs/tags/2025-02-10.tar.gz"

# Cursor Theme: Bibata-Modern-Classic
BIBATA_URL="https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.7/Bibata-Modern-Classic.tar.gz"

# Fonts
INTER_URL="https://github.com/rsms/inter/releases/download/v4.1/Inter-4.1.zip"
MAPLE_MONO_URL="https://github.com/subframe7536/Maple-font/releases/download/v7.0/MapleMono-NF-unhinted.zip"

# ── Download Theme ──────────────────────────────────────────
echo ""
echo "[1/5] Nordic GTK Theme..."
mkdir -p themes/nordic
curl -fsSL "$NORDIC_URL" -o /tmp/nordic.tar.xz
tar -xJf /tmp/nordic.tar.xz -C themes/nordic --strip-components=1 2>/dev/null || true
echo "  -> themes/nordic/"

# ── Download Icons ──────────────────────────────────────────
echo "[2/5] WhiteSur-dark Icons..."
mkdir -p icons/whitesur
curl -fsSL "$WHITESUR_URL" -o /tmp/whitesur.tar.gz
tar -xzf /tmp/whitesur.tar.gz -C icons/whitesur --strip-components=1 2>/dev/null || cp /tmp/whitesur.tar.gz icons/whitesur/
echo "  -> icons/whitesur/"

# ── Download Cursors ────────────────────────────────────────
echo "[3/5] Bibata-Modern-Classic Cursors..."
mkdir -p cursors/bibata
curl -fsSL "$BIBATA_URL" -o /tmp/bibata.tar.gz
tar -xzf /tmp/bibata.tar.gz -C cursors/bibata --strip-components=1 2>/dev/null || true
echo "  -> cursors/bibata/"

# ── Download Fonts ──────────────────────────────────────────
echo "[4/5] Inter Font..."
mkdir -p fonts/inter
curl -fsSL "$INTER_URL" -o /tmp/inter.zip
unzip -qo /tmp/inter.zip -d fonts/inter/ 2>/dev/null || true
echo "  -> fonts/inter/"

echo "[5/5] Maple Mono NF Font..."
mkdir -p fonts/maple-mono
curl -fsSL "$MAPLE_MONO_URL" -o /tmp/maple-mono.zip
unzip -qo /tmp/maple-mono.zip -d fonts/maple-mono/ 2>/dev/null || true
echo "  -> fonts/maple-mono/"

echo ""
echo "============================================"
echo "  Download complete!"
echo "============================================"
echo "  Themes:  assets/themes/nordic/"
echo "  Icons:   assets/icons/whitesur/"
echo "  Cursors: assets/cursors/bibata/"
echo "  Fonts:   assets/fonts/inter/"
echo "  Fonts:   assets/fonts/maple-mono/"
echo ""
echo "  Offline install (after extracting):"
echo "    sudo cp -r themes/nordic/*       /usr/share/themes/"
echo "    sudo cp -r icons/whitesur/*      /usr/share/icons/"
echo "    sudo cp -r cursors/bibata/*      /usr/share/icons/"
echo "    sudo cp -r fonts/inter/*         /usr/share/fonts/"
echo "    sudo cp -r fonts/maple-mono/*    /usr/share/fonts/"
echo "    sudo fc-cache -f"
