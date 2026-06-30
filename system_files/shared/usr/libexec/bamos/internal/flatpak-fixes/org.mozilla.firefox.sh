#!/usr/bin/env bash
# Flatpak fix for Firefox: ensures proper GTK theme integration and VA-API
# Adapted from RakuOS flatpak-fixes/org.mozilla.firefox.sh
set -euo pipefail

APPID="org.mozilla.firefox"
ACTION="${1:-install}"

case "$ACTION" in
    install)
        echo "[bamos-flatpak-fix] Applying Firefox fixes..."

        # Enable Wayland by default
        flatpak override --user --env=MOZ_ENABLE_WAYLAND=1 "$APPID" 2>/dev/null || true

        # Enable hardware video decoding (VA-API)
        flatpak override --user --env=MOZ_DISABLE_RDD_SANDBOX=1 "$APPID" 2>/dev/null || true
        flatpak override --user --env=MOZ_X11_EGL=1 "$APPID" 2>/dev/null || true

        # Allow access to Vietnamese fonts and themes
        flatpak override --user \
            --filesystem=xdg-data/fonts:ro \
            --filesystem=/usr/share/fonts/bamos:ro \
            "$APPID" 2>/dev/null || true

        echo "[bamos-flatpak-fix] Firefox fixes applied."
        ;;
    uninstall)
        echo "[bamos-flatpak-fix] Firefox uninstalled — cleaning overrides..."
        flatpak override --user --reset "$APPID" 2>/dev/null || true
        ;;
esac
