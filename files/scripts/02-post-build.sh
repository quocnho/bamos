#!/usr/bin/env bash
set -ouex pipefail

echo "=== BamOS Post-Build ==="

IMAGE_NAME="${IMAGE_NAME:-bamos}"

# ── Build initramfs for CachyOS kernel ────────────────────────────────────────
QUALIFIED_KERNEL=$(rpm -q --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}\n' kernel-cachyos 2>/dev/null || echo "")
if [[ -n "$QUALIFIED_KERNEL" ]]; then
    echo "Building initramfs for kernel: $QUALIFIED_KERNEL"
    depmod "$QUALIFIED_KERNEL" 2>/dev/null || true
    dracut --no-hostonly --kver "$QUALIFIED_KERNEL" --reproducible --zstd -v \
        --add ostree --add fido2 -f "/usr/lib/modules/$QUALIFIED_KERNEL/initramfs.img" 2>/dev/null || true
fi

# ── Set default hostname ─────────────────────────────────────────────────────
echo "bamos" > /etc/hostname

# ── Rebuild initramfs with all modules ──────────────────────────────────────
/usr/libexec/ublue-os/initramfs/build-initramfs 2>/dev/null || true

echo "=== BamOS Post-Build Complete ==="
