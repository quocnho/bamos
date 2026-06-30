#!/usr/bin/bash
# bamos-install-store.sh — Install BamOS Store (adapted from Bazaar)
# BamStore is a modern GNOME app store for discovering and installing apps.
# https://github.com/bazaar-org/bazaar (forked at https://github.com/quocnho/bamstore)
#
# This script installs BamStore via Flatpak from the BamOS Flatpak remote.
# In the future, it can also build from source using meson/ninja.

set -euo pipefail

echo "[bamos] Setting up BamOS Store (BamStore)..."

# =============================================================================
# Option 1: Install from Flatpak (recommended for end users)
# =============================================================================

FLATPAK_APP_ID="org.bamstore.BamStore"

if command -v flatpak &>/dev/null; then
    # Check if already installed
    if flatpak list --system 2>/dev/null | grep -q "$FLATPAK_APP_ID"; then
        echo "[bamos] BamStore is already installed via Flatpak."
        exit 0
    fi

    # Try installing from Flathub first (Bazaar is available there)
    echo "[bamos] Installing BamStore (Bazaar) from Flathub..."
    echo "[bamos] Adding Flathub remote..."
    flatpak remote-add --if-not-exists --system flathub https://dl.flathub.org/repo/flathub.flatpakrepo || \
        echo "[bamos] Flathub remote-add failed"

    echo "[bamos] Installing Bazaar from Flathub..."
    if flatpak install -y --noninteractive --system flathub io.github.bazaar_org.bazaar; then
        echo "[bamos] BamStore installed successfully from Flathub."
        echo "[bamos] Launch with: flatpak run io.github.bazaar_org.bazaar"
        exit 0
    else
        echo "[bamos] Flatpak install failed — will defer to first boot."
    fi

    echo "[bamos] Flatpak installation not available — will install as native package."
fi

# =============================================================================
# Option 2: Build from source (for developers / custom builds)
# =============================================================================

# Check if bamstore source is available at /opt/bamos/bamstore
BAMSTORE_SRC="/opt/bamos/bamstore"
BAMSTORE_BUILD_DIR="/opt/bamos/bamstore-build"

if [[ -d "$BAMSTORE_SRC" ]]; then
    echo "[bamos] Building BamStore from source at $BAMSTORE_SRC..."

    # Install build dependencies
    echo "[bamos] Installing build dependencies..."
    rpm-ostree install \
        meson \
        ninja-build \
        gcc \
        gcc-c++ \
        pkgconfig \
        gtk4-devel \
        libadwaita-devel \
        json-glib-devel \
        libsoup3-devel \
        2>/dev/null || echo "[bamos] Some build deps already installed"

    # Build
    mkdir -p "$BAMSTORE_BUILD_DIR"
    cd "$BAMSTORE_SRC"

    if [[ -f meson.build ]]; then
        meson setup "$BAMSTORE_BUILD_DIR" --prefix=/usr
        ninja -C "$BAMSTORE_BUILD_DIR"
        ninja -C "$BAMSTORE_BUILD_DIR" install

        echo "[bamos] BamStore built and installed from source."
        echo "[bamos] Launch with: bamstore"
    else
        echo "[bamos] ERROR: meson.build not found in $BAMSTORE_SRC"
        exit 1
    fi
else
    echo "[bamos] BamStore source not found at $BAMSTORE_SRC"
    echo "[bamos] To install BamStore:"
    echo "  1. Clone: git clone https://github.com/quocnho/bamstore /opt/bamos/bamstore"
    echo "  2. Re-run: bamos-install-store.sh"
    echo ""
    echo "[bamos] Or install via Flatpak:"
    echo "  flatpak install flathub io.github.bazaar_org.bazaar"
fi

echo "[bamos] BamStore setup complete."
