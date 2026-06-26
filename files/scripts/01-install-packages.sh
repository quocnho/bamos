#!/usr/bin/env bash
set -ouex pipefail

echo "=== BamOS Package Installation ==="

IMAGE_NAME="${IMAGE_NAME:-bamos}"
FEDORA_VERSION=$(rpm -E %fedora)

# ── Detect DE variant ─────────────────────────────────────────────────────────
IS_KDE=false
IS_GNOME=false
IS_COSMIC=false
[[ "$IMAGE_NAME" == *-kde* ]] && IS_KDE=true
[[ "$IMAGE_NAME" == *-gnome* ]] && IS_GNOME=true
[[ "$IMAGE_NAME" == *-cosmic* ]] && IS_COSMIC=true

# ── Common packages ───────────────────────────────────────────────────────────
dnf5 -y install \
    steam-devices \
    dkms-xpad-noone \
    dkms-xone \
    xone-firmware \
    dkms-zenergy

# Remove conflicting base packages
dnf5 -y remove firefox* nss 2>/dev/null || true

# ── KDE-specific packages ─────────────────────────────────────────────────────
if [[ "$IS_KDE" == "true" ]]; then
    echo "Installing KDE-specific packages..."
    dnf5 -y install \
        kdeconnectd \
        plasma-systemmonitor \
        kate \
        gwenview \
        kdenlive \
        krdp \
        kdeplasma-addons
fi

# ── GNOME-specific packages ───────────────────────────────────────────────────
if [[ "$IS_GNOME" == "true" ]]; then
    echo "Installing GNOME-specific packages..."
    dnf5 -y install \
        nautilus-gsconnect \
        gnome-tweaks \
        gnome-extensions-app
fi

# ── COSMIC-specific packages ──────────────────────────────────────────────────
if [[ "$IS_COSMIC" == "true" ]]; then
    echo "COSMIC edition — COSMIC DE is provided by base image."
fi

echo "=== BamOS Package Installation Complete ==="
