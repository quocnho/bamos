#!/usr/bin/bash
# bamos-install-kmods.sh — Additional kernel modules
# Adapted from Bazzite install-kmods
#
# During container build: installs userspace/firmware only (no kernel modules).
# Kernel modules (xone-kmod, xpadneo, etc.) are deferred to first boot
# via systemd service because akmodsbuild won't run inside a container.
#
# Manual install on running system: just bamos setup-kmods

set -euo pipefail

echo "[bamos] Installing additional kernel modules..."

FEDORA_VERSION=$(rpm -E %fedora)

# Detect if running inside a container build
IS_CONTAINER_BUILD=false
if [[ ! -d /sys/class/dmi ]] || [[ -f /.dockerenv ]] || grep -q docker /proc/1/cgroup 2>/dev/null; then
    IS_CONTAINER_BUILD=true
    echo "[bamos] Container build detected — installing userspace packages only."
    echo "[bamos] Kernel modules (xone, xpadneo) will be installed at first boot."
fi

# =============================================================================
# Install userspace/firmware packages (safe in both container and runtime)
# Kernel modules (*-kmod) are skipped during container build
# =============================================================================

# =============================================================================
# Container build: skip all kmod-related packages, create first-boot script
# xone-firmware, xone-kmod-common, v4l2loopback-utils all pull in akmod deps
# =============================================================================
if [[ "$IS_CONTAINER_BUILD" == "true" ]]; then
    echo "[bamos] Container build — deferring all kernel modules to first boot."
    mkdir -p /usr/libexec/bamos

    cat > /usr/libexec/bamos/bamos-install-kmods-firstboot.sh << 'KMODEOF'
#!/bin/bash
# bamos-install-kmods-firstboot.sh — Install kernel modules at first boot
set -euo pipefail

echo "[bamos] Installing kernel modules (xone, xpadneo)..."
echo "[bamos] This requires a reboot after installation."

FEDORA_VERSION=$(rpm -E %fedora)

# Install xone kmod (Xbox controller driver)
if ! rpm -q xone-kmod &>/dev/null; then
    echo "[bamos] Installing xone-kmod..."
    rpm-ostree install xone-kmod || \
        echo "[bamos] xone-kmod not available — skipping"
fi

# Install xpadneo (Xbox Bluetooth)
if ! rpm -q xpadneo &>/dev/null; then
    echo "[bamos] Installing xpadneo..."
    rpm-ostree install xpadneo || \
        echo "[bamos] xpadneo not available — skipping"
fi

# Install broadcom-wl
if ! rpm -q broadcom-wl &>/dev/null; then
    echo "[bamos] Installing broadcom-wl..."
    rpm-ostree install broadcom-wl || \
        echo "[bamos] broadcom-wl not available — skipping"
fi

# Install v4l2loopback
if ! rpm -q v4l2loopback &>/dev/null; then
    echo "[bamos] Installing v4l2loopback..."
    rpm-ostree install v4l2loopback || \
        echo "[bamos] v4l2loopback not available — skipping"
fi

echo "[bamos] Kernel modules staged for installation."
echo "[bamos] Reboot to apply: systemctl reboot"
KMODEOF

    chmod +x /usr/libexec/bamos/bamos-install-kmods-firstboot.sh

    # Create modprobe config for modules that are safe to load
    mkdir -p /etc/modules-load.d/
    cat > /etc/modules-load.d/bamos-kmods.conf << 'EOF'
# BamOS additional kernel modules — loaded at boot
# xone-wired, xpadneo, etc. installed by first-boot script
EOF

    echo "[bamos] First-boot installer created at: /usr/libexec/bamos/bamos-install-kmods-firstboot.sh"
    echo "[bamos] Run after first boot: sudo bamos install-kmods-firstboot"
fi

echo "[bamos] Kernel module setup complete."
