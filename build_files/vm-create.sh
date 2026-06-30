#!/usr/bin/env bash
# bamos-vm-create.sh — Create a KVM VM from a BamOS ISO
# Usage: bamos-vm-create.sh [variant]
#   variant: gnome|kde|gnome-nvidia|kde-nvidia (default: gnome)
set -euo pipefail

VARIANT="${1:-gnome}"
VM_NAME="bamos-${VARIANT}"
ISO_DIR="/var/home/quocnho/Projects/bamos/output/bootiso"
ISO_FILE=$(ls -t "$ISO_DIR"/*.iso 2>/dev/null | head -1)
RAM_MB="${RAM:-4096}"
CPU_CORES="${CPU:-4}"
DISK_GB="${DISK:-40}"

# =============================================================================
# Find ISO
# =============================================================================
if [[ -z "$ISO_FILE" ]]; then
    echo "❌ No ISO found in $ISO_DIR"
    echo "   Build one first: just build-iso-$VARIANT"
    exit 1
fi
echo "🐉 Using ISO: $(basename "$ISO_FILE")"

# =============================================================================
# Check if VM already exists
# =============================================================================
if virsh dominfo "$VM_NAME" &>/dev/null; then
    echo "⚠️  VM '$VM_NAME' already exists."
    echo "   To remove: virsh undefine $VM_NAME --remove-all-storage"
    exit 1
fi

# =============================================================================
# Create disk image
# =============================================================================
DISK_PATH="$HOME/.local/share/libvirt/images/${VM_NAME}.qcow2"
echo "💾 Creating disk: $DISK_PATH (${DISK_GB}G)"
qemu-img create -f qcow2 "$DISK_PATH" "${DISK_GB}G" &>/dev/null

# =============================================================================
# Install VM
# =============================================================================
echo "🚀 Creating VM '$VM_NAME'..."
echo "   RAM: ${RAM_MB}MB, CPU: ${CPU_CORES} cores, Disk: ${DISK_GB}G"

virt-install \
    --name "$VM_NAME" \
    --ram "$RAM_MB" \
    --vcpus "$CPU_CORES" \
    --disk path="$DISK_PATH",format=qcow2 \
    --cdrom "$ISO_FILE" \
    --os-variant detect=on,require=off \
    --network network=default,model=virtio \
    --graphics spice \
    --video qxl \
    --sound none \
    --boot uefi \
    --tpm none \
    --events on_reboot=destroy \
    --check disk_size=off \
    --wait -1  # Wait for installation to complete

echo ""
echo "✅ VM '$VM_NAME' created and installation started."
echo "   - Connect: virt-viewer $VM_NAME"
echo "   - Console: virsh console $VM_NAME"
echo "   - Start:   virsh start $VM_NAME"
echo "   - Destroy: virsh destroy $VM_NAME"
echo "   - Remove:  virsh undefine $VM_NAME --remove-all-storage"
