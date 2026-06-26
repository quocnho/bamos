#!/usr/bin/env bash
set -ouex pipefail

echo "=== BamOS: NVIDIA Setup ==="

IMAGE_NAME="${IMAGE_NAME:-bamos}"

if [[ "$IMAGE_NAME" != *-nvidia ]]; then
    echo "Not an NVIDIA variant — skipping."
    exit 0
fi

echo "Configuring NVIDIA driver integration..."

# ── Ensure nouveau Vulkan ICDs exist (for compatibility) ─────────────────────
(
    shopt -u nullglob
    ls /usr/share/vulkan/icd.d/nouveau_icd.*.json &>/dev/null
) || {
    echo "WARNING: No nouveau Vulkan ICDs found. Mesa may need reinstall."
    dnf5 -y reinstall mesa-vulkan-drivers 2>/dev/null || true
}

# ── NVIDIA udev rules ────────────────────────────────────────────────────────
mkdir -p /etc/udev/rules.d
cat > /etc/udev/rules.d/80-nvidia-pm.rules << 'EOF'
ACTION=="add", DEVPATH=="/bus/pci/drivers/nvidia", RUN+="/sbin/modprobe nvidia-drm"
ACTION=="add", DEVPATH=="/bus/pci/drivers/nvidia", RUN+="/sbin/modprobe nvidia-uvm"
EOF

# ── NVIDIA power management service ──────────────────────────────────────────
mkdir -p /etc/systemd/system
cat > /etc/systemd/system/nvidia-suspend.service << 'EOF'
[Unit]
Description=NVIDIA system suspend/resume
Before=systemd-suspend.service

[Service]
Type=oneshot
ExecStart=/usr/bin/nvidia-sleep.sh suspend
ExecStop=/usr/bin/nvidia-sleep.sh resume

[Install]
WantedBy=systemd-suspend.service
EOF

echo "=== BamOS: NVIDIA Setup Complete ==="
