#!/usr/bin/bash
# bamos-install-portal.sh — Install BamOS Portal GTK4 App
# BamOS Portal is a tabbed first-boot setup wizard, adapted from Bazzite Portal (yafti-gtk)
# This script installs Python dependencies and registers the application.

set -euo pipefail

echo "[bamos] Setting up BamOS Portal..."

PORTAL_PY="/usr/libexec/bamos/bamos-portal.py"
PORTAL_DESKTOP="/usr/share/applications/io.bamos.Portal.desktop"
PORTAL_CONFIG="/usr/share/bamos/portal/portal.yml"

# =============================================================================
# 1. Install Python dependencies
# =============================================================================

echo "[bamos] Installing Python GTK4 dependencies..."
pip install --prefix=/usr PyGObject PyYAML 2>/dev/null || \
    echo "[bamos] Python deps may already be installed via RPM"

# Ensure pygobject3 and python3-pyyaml are available via RPM
rpm-ostree install \
    python3-gobject \
    python3-pyyaml \
    2>/dev/null || echo "[bamos] Python RPM packages already installed"

# =============================================================================
# 2. Ensure script is executable
# =============================================================================

chmod +x "$PORTAL_PY" 2>/dev/null || true

# =============================================================================
# 3. Update desktop database
# =============================================================================

if command -v update-desktop-database &>/dev/null; then
    update-desktop-database /usr/share/applications 2>/dev/null || true
fi

# =============================================================================
# 4. Create autostart entry for first boot
# =============================================================================

mkdir -p /etc/skel/.config/autostart
cp "$PORTAL_DESKTOP" /etc/skel/.config/autostart/io.bamos.Portal.desktop 2>/dev/null || true

echo "[bamos] BamOS Portal installed."
echo "[bamos] Configuration: $PORTAL_CONFIG"
echo "[bamos] Launch with: bamos portal"
echo "[bamos] Or open BamOS Portal from the applications menu."
