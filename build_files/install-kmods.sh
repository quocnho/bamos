#!/usr/bin/bash
# bamos-install-kmods.sh — Install additional kernel modules (adapted from Bazzite install-kmods)
# Installs community-maintained kernel modules for hardware support:
#   - xone: Xbox One/Series X|S gamepad driver (USB + wireless dongle)
#   - xpadneo: Xbox One S/X Bluetooth gamepad driver
#   - broadcom-wl: Broadcom wireless chipsets (BCM4311, BCM4312, BCM4313, BCM4321, etc.)
#   - v4l2loopback: Virtual video device for OBS Virtual Camera, DroidCam

set -eoux pipefail

echo "[bamos] Installing additional kernel modules..."

FEDORA_VERSION=$(rpm -E %fedora)
RELEASE_RPM="https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VERSION}.noarch.rpm"
NONFREE_RPM="https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VERSION}.noarch.rpm"

# =============================================================================
# 1. Enable RPM Fusion repos if not already enabled
# =============================================================================

rpm-ostree install \
    "$RELEASE_RPM" \
    "$NONFREE_RPM" \
    || true

# =============================================================================
# 2. Install xone — Xbox One/Series X|S Controller Driver
#    Supports: Xbox One, Xbox One S, Xbox Series X|S, Xbox Elite 2
#    Connection: USB wired + Xbox Wireless Dongle
# =============================================================================

echo "[bamos] Installing xone (Xbox controller driver)..."
rpm-ostree install xone-kmod-common xone-kmod || {
    echo "[bamos] xone not available from RPM Fusion — trying COPR..."
    # Fallback: COPR repository
    if ! rpm -q xone-kmod-common &>/dev/null; then
        curl -sL "https://copr.fedorainfracloud.org/coprs/sentry/xone/repo/fedora-${FEDORA_VERSION}/sentry-xone-fedora-${FEDORA_VERSION}.repo" \
            -o /etc/yum.repos.d/_copr_sentry-xone.repo 2>/dev/null || true
        rpm-ostree install xone-firmware xone-kmod-common xone-kmod || echo "[bamos] xone installation skipped"
        rm -f /etc/yum.repos.d/_copr_sentry-xone.repo
    fi
}

# =============================================================================
# 3. Install xpadneo — Xbox One S/X Bluetooth Controller Driver
#    Supports: Xbox One S (1708+), Xbox Series X|S over Bluetooth
#    Connection: Bluetooth only
# =============================================================================

echo "[bamos] Installing xpadneo (Xbox Bluetooth controller driver)..."
rpm-ostree install xpadneo || {
    echo "[bamos] xpadneo not available from RPM Fusion — trying COPR..."
    if ! rpm -q xpadneo &>/dev/null; then
        curl -sL "https://copr.fedorainfracloud.org/coprs/atar-axis/xpadneo/repo/fedora-${FEDORA_VERSION}/atar-axis-xpadneo-fedora-${FEDORA_VERSION}.repo" \
            -o /etc/yum.repos.d/_copr_atar-xpadneo.repo 2>/dev/null || true
        rpm-ostree install xpadneo || echo "[bamos] xpadneo installation skipped"
        rm -f /etc/yum.repos.d/_copr_atar-xpadneo.repo
    fi
}

# =============================================================================
# 4. Install broadcom-wl — Broadcom Wireless Driver
#    Supports many older Broadcom WiFi chipsets commonly found in laptops
# =============================================================================

echo "[bamos] Installing broadcom-wl (Broadcom wireless driver)..."
rpm-ostree install broadcom-wl || {
    echo "[bamos] broadcom-wl not available — skipping (may not be needed)"
}

# =============================================================================
# 5. Install v4l2loopback — Virtual Video Device
#    Required for: OBS Virtual Camera, DroidCam, video loopback
# =============================================================================

echo "[bamos] Installing v4l2loopback (virtual camera support)..."
rpm-ostree install v4l2loopback || {
    echo "[bamos] v4l2loopback not available — skipping"
}

# =============================================================================
# 6. Modprobe configuration
# =============================================================================

# Ensure modules load at boot
mkdir -p /etc/modules-load.d/

cat > /etc/modules-load.d/bamos-kmods.conf <<'EOF'
# BamOS additional kernel modules
# Xbox controllers
xone-wired
# Broadcom WiFi
# wl
# Virtual camera (load manually: modprobe v4l2loopback)
EOF

echo "[bamos] Kernel module installation complete."
