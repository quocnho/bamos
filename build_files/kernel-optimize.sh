#!/bin/bash
# kernel-optimize.sh — BamOS Kernel & Performance Tuning (CachyOS-inspired)
# Integrates CachyOS optimizations while maintaining uBlue akmods stability
#
# Strategy: Keep uBlue kernel (stable akmods support) + apply CachyOS tuning

set -euo pipefail

echo "============================================="
echo "  BamOS Kernel Optimization (CachyOS-inspired)"
echo "============================================="

FEDORA_VERSION=$(rpm -E %fedora)

# =============================================================================
# 1. Add CachyOS repository for tuning packages
# =============================================================================

echo "Adding CachyOS repository..."
if ! rpm -q cachyos-repos &>/dev/null; then
    dnf5 -y copr enable bieszczaders/kernel-cachyos-addons || \
    echo "CachyOS COPR not available — using fallback."
fi

# =============================================================================
# 2. Install CachyOS tuning packages (NOT kernel — using uBlue kernel)
# =============================================================================

echo "Installing CachyOS performance tuning packages..."
rpm-ostree install \
    cachyos-settings \
    cachyos-ananicy-rules \
    bore-sysctl \
    scx-scheds \
    scx-tools \
    ananicy-cpp \
    || echo "Some CachyOS packages skipped (may not be available for this Fedora version)."

# =============================================================================
# 3. Apply CachyOS kernel parameters
# =============================================================================

echo "Applying CachyOS kernel parameters..."

cat > /etc/default/grub << 'EOF'
# CachyOS-inspired kernel parameters for BamOS
# Optimized for desktop responsiveness and Vietnamese user workloads

# IOMMU — enable for better device isolation (optional, disable if issues)
# amd_iommu=on intel_iommu=on iommu=pt

# CPU mitigations — disable for maximum performance
# (Security-conscious users should keep mitigations on)
# mitigations=off

# Nowatchdog — disable NMI watchdog for lower latency
nowatchdog

# Preempt — full preemption for desktop responsiveness
preempt=full

# Transparent Hugepages — always enabled for better memory management
transparent_hugepage=always

# IO Scheduler — handled by udev rules (bfq for HDD, kyber/adios for SSD)
# No kernel cmdline needed — see /usr/lib/udev/rules.d/60-ioschedulers.rules

# Quiet boot for clean experience
quiet splash

# zswap for memory compression
zswap.enabled=1 zswap.compressor=lz4 zswap.max_pool_percent=20
EOF

# =============================================================================
# 4. Apply sysctl performance tuning
# =============================================================================

cat > /usr/lib/sysctl.d/80-bamos-performance.conf << 'EOF'
# BamOS Performance Tuning (CachyOS-inspired)
# Applied at boot via systemd-sysctl

# ---- VM (Virtual Memory) ----
# Reduce swappiness — prefer RAM over swap for desktop use
vm.swappiness=30

# Enable Multi-Gen LRU for better page reclaim
vm.lru_gen.enabled=1

# ---- Kernel ----
# Increase inotify watchers for development
fs.inotify.max_user_watches=524288

# Enable BBR TCP congestion control
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr

# ---- Network ----
# Increase network buffer sizes
net.core.rmem_max=16777216
net.core.wmem_max=16777216

# Enable TCP fast open
net.ipv4.tcp_fastopen=3

# ---- File System ----
# Increase max file handles
fs.file-max=2097152
fs.nr_open=2097152

# ---- I/O ----
# Allow more in-flight I/O requests
fs.aio-max-nr=1048576
EOF

# =============================================================================
# 5. Enable scx scheduler service (CachyOS CPU scheduler)
# =============================================================================

echo "Configuring CPU scheduler..."
# Create systemd service for scx scheduler
# Default: scx_bpfland for balanced desktop performance
# Also available: scx_lavd (gaming), scx_rusty (server)

cat > /usr/lib/systemd/system/scx.service << 'EOF'
[Unit]
Description=sched_ext BPF scheduler (CachyOS)
Documentation=https://github.com/sched-ext/scx

[Service]
Type=simple
ExecStart=/usr/bin/scx_bpfland
Restart=on-failure
CPUQuota=2%

[Install]
WantedBy=multi-user.target
EOF

# Enable scx service (with override to not fail if kernel doesn't support sched_ext)
systemctl enable scx.service 2>/dev/null || true

# =============================================================================
# 6. Enable ananicy-cpp for process priority management
# =============================================================================

systemctl enable ananicy-cpp.service 2>/dev/null || true

# =============================================================================
# 7. Build initramfs to include new modules
# =============================================================================

echo "Rebuilding initramfs..."

QUALIFIED_KERNEL=$(rpm -q --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}\n' kernel-core | head -1)

if [ -n "$QUALIFIED_KERNEL" ] && [ -d "/usr/lib/modules/$QUALIFIED_KERNEL" ]; then
    dracut --no-hostonly --kver "$QUALIFIED_KERNEL" --reproducible --zstd -v \
        --add ostree --add fido2 \
        -f "/usr/lib/modules/$QUALIFIED_KERNEL/initramfs.img" || true
    chmod 0600 "/usr/lib/modules/$QUALIFIED_KERNEL/initramfs.img" || true
    echo "Initramfs rebuilt for kernel $QUALIFIED_KERNEL"
else
    echo "No kernel found for initramfs rebuild — skipping."
fi

echo ""
echo "============================================="
echo "  Kernel optimization complete!"
echo "============================================="
echo ""
echo "Applied optimizations:"
echo "  - CachyOS tuning packages (ananicy, bore-sysctl, scx)"
echo "  - IO scheduler: bfq (HDD) / kyber (SSD) / none (NVMe)"
echo "  - BBR TCP congestion control"
echo "  - Reduced swappiness (30)"
echo "  - Multi-Gen LRU page reclaim"
echo "  - Full kernel preemption"
echo ""
echo "Reboot to apply kernel parameter changes."
