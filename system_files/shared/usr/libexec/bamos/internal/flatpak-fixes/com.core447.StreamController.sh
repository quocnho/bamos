#!/usr/bin/env bash
# Flatpak fix for StreamController: udev rules and device permissions
# Adapted from RakuOS flatpak-fixes/com.core447.StreamController.sh
set -euo pipefail

APPID="com.core447.StreamController"
ACTION="${1:-install}"

case "$ACTION" in
    install)
        echo "[bamos-flatpak-fix] Applying StreamController fixes..."

        # Allow access to USB devices for Elgato Stream Deck
        flatpak override --user \
            --device=all \
            --socket=udev \
            "$APPID" 2>/dev/null || true

        # Create udev rules for Stream Deck if not present
        if [[ ! -f /etc/udev/rules.d/99-streamdeck.rules ]]; then
            cat > /etc/udev/rules.d/99-streamdeck.rules <<'UDEV'
# Elgato Stream Deck
SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="0060", MODE="0660", TAG+="uaccess"
SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="0063", MODE="0660", TAG+="uaccess"
SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="006c", MODE="0660", TAG+="uaccess"
SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="006d", MODE="0660", TAG+="uaccess"
SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="0080", MODE="0660", TAG+="uaccess"
SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="0084", MODE="0660", TAG+="uaccess"
SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="008f", MODE="0660", TAG+="uaccess"
UDEV
            udevadm control --reload-rules 2>/dev/null || true
            udevadm trigger 2>/dev/null || true
        fi

        echo "[bamos-flatpak-fix] StreamController fixes applied."
        ;;
    uninstall)
        echo "[bamos-flatpak-fix] StreamController uninstalled — cleaning overrides..."
        flatpak override --user --reset "$APPID" 2>/dev/null || true
        ;;
esac
