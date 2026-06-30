#!/bin/bash
# gnome-build.sh — BamOS GNOME Desktop Build (RakuOS-inspired)
# Installs GNOME desktop + RakuOS-style theming + Vietnamese optimizations

set -euo pipefail

echo "============================================="
echo "  BamOS GNOME Build (RakuOS-inspired)"
echo "============================================="

FEDORA_VERSION=$(rpm -E %fedora)

# =============================================================================
# GNOME Core Packages
# =============================================================================

echo "Installing GNOME core packages..."

rpm-ostree install \
    adw-gtk3-theme \
    file-roller \
    gdm \
    gnome-backgrounds \
    gnome-bluetooth \
    gnome-calculator \
    gnome-calendar \
    gnome-control-center \
    gnome-disk-utility \
    gnome-extensions-app \
    gnome-session \
    gnome-settings-daemon \
    gnome-shell \
    gnome-shell-extension-appindicator \
    gnome-shell-extension-blur-my-shell \
    gnome-shell-extension-caffeine \
    gnome-shell-extension-dash-to-dock \
    gnome-shell-extension-no-overview \
    gnome-system-monitor \
    gnome-text-editor \
    gnome-tweaks \
    gvfs-nfs \
    loupe \
    nautilus \
    ptyxis \
    papers \
    evince \
    xdg-desktop-portal \
    xdg-desktop-portal-gnome \
    xdg-desktop-portal-gtk \
    xdg-user-dirs-gtk \
    || echo "Some GNOME packages skipped."

# =============================================================================
# RakuOS-style themes & icons
# =============================================================================

echo "Installing RakuOS-style themes and fonts..."

rpm-ostree install \
    bibata-cursor-theme \
    rsms-inter-fonts \
    maple-fonts \
    || echo "Theme/font packages skipped."

# Install WhiteSur icon theme (same as RakuOS)
echo "Installing WhiteSur icon theme..."
git clone --depth 1 https://github.com/vinceliuice/WhiteSur-icon-theme.git /tmp/WhiteSur-icon-theme 2>/dev/null && \
    /tmp/WhiteSur-icon-theme/install.sh -b -a -t all && \
    rm -rf /tmp/WhiteSur-icon-theme || \
    echo "WhiteSur icon theme installation skipped."

# =============================================================================
# GNOME GSsettings Compilation
# =============================================================================

echo "Compiling GNOME GSettings schemas..."
glib-compile-schemas /usr/share/glib-2.0/schemas/

# =============================================================================
# Enable GDM
# =============================================================================

systemctl enable gdm.service

# =============================================================================
# Remove unwanted packages (KEEP gnome-extensions-app + gnome-tweaks for user customization)

rpm-ostree remove \
    gnome-tour \
    gnome-classic-session \
    gnome-initial-setup \
    || echo "Package removal skipped."

# =============================================================================
# Sudoers configuration
# =============================================================================

chown root:root /etc/sudoers.d/bamos-software 2>/dev/null || true
chmod 0440 /etc/sudoers.d/bamos-software 2>/dev/null || true

echo "BamOS GNOME build complete!"
