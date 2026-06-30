#!/usr/bin/env bash
# bamos-vm-setup.sh — Set up KVM/QEMU virtual machine for testing BamOS ISOs
# Run this on your developer machine (not inside the container)
set -euo pipefail

echo "[bamos] Setting up VM environment..."

# =============================================================================
# 1. Enable libvirtd service
# =============================================================================
echo "[bamos] Enabling libvirtd..."
sudo systemctl enable --now libvirtd 2>/dev/null || true
sudo systemctl enable --now virtnetworkd 2>/dev/null || true

# =============================================================================
# 2. Add user to libvirt group
# =============================================================================
echo "[bamos] Adding $USER to libvirt group..."
sudo usermod -aG libvirt "$USER"
echo "  ⚠️  Log out and back in for group changes to take effect."
echo "     Or run: newgrp libvirt"

# =============================================================================
# 3. Create default network (NAT)
# =============================================================================
echo "[bamos] Creating default NAT network..."
if ! virsh net-list --all 2>/dev/null | grep -q default; then
    sudo virsh net-define /usr/share/libvirt/networks/default.xml 2>/dev/null || true
fi
sudo virsh net-start default 2>/dev/null || true
sudo virsh net-autostart default 2>/dev/null || true

# =============================================================================
# 4. Create storage pool
# =============================================================================
echo "[bamos] Creating VM storage pool..."
mkdir -p "$HOME/.local/share/libvirt/images"
if ! virsh pool-list --all 2>/dev/null | grep -q bamos; then
    virsh pool-define-as --name bamos --type dir --target "$HOME/.local/share/libvirt/images" 2>/dev/null || true
fi
virsh pool-start bamos 2>/dev/null || true
virsh pool-autostart bamos 2>/dev/null || true

# =============================================================================
# 5. Download virtio drivers for Windows VMs (optional)
# =============================================================================
# Not needed for Linux, only if you plan to test Windows VMs

echo "[bamos] VM environment ready!"
echo ""
echo "Next steps:"
echo "  1. Log out and back in (or run: newgrp libvirt)"
echo "  2. Launch virt-manager to create a VM"
echo "     Or use: just vm-create"
