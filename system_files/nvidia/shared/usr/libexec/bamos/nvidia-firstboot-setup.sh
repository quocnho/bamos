#!/bin/bash
# nvidia-firstboot-setup.sh
# Runs on first boot to auto-detect NVIDIA GPU and install correct driver
# Supports auto-switching between nvidia-open and nvidia (closed) drivers
# This runs as a oneshot systemd service on first boot

set -e

LOG_FILE="/var/log/bamos-nvidia-setup.log"
echo "BamOS NVIDIA First-Boot Setup started at $(date)" | tee -a "$LOG_FILE"

# =============================================================================
# Detect NVIDIA GPU
# =============================================================================

if ! lspci -nn | grep -qi "nvidia"; then
    echo "No NVIDIA GPU detected. Exiting." | tee -a "$LOG_FILE"
    systemctl disable bamos-nvidia-firstboot.service 2>/dev/null || true
    exit 0
fi

# Get PCI ID
NVIDIA_PCI_ID=$(lspci -nn | grep -i "nvidia" | grep -oP '\[\K[0-9A-F]{4}:[0-9A-F]{4}(?=\])' | head -1)
echo "Detected NVIDIA GPU PCI ID: $NVIDIA_PCI_ID" | tee -a "$LOG_FILE"

# =============================================================================
# Determine which driver is needed
# =============================================================================

NEEDS_LEGACY=false

# Check if GPU needs the closed-source driver (Maxwell/Pascal/Volta/Kepler)
case "$NVIDIA_PCI_ID" in
    10DE:0F*|10DE:10*)  # Kepler (GTX 600/700)
        NEEDS_LEGACY=true
        GPU_GEN="Kepler"
        ;;
    10DE:11*|10DE:12*)  # Maxwell v1 (GTX 700 series Maxwell)
        NEEDS_LEGACY=true
        GPU_GEN="Maxwell v1"
        ;;
    10DE:13*|10DE:14*|10DE:15*)  # Maxwell v2 (GTX 900 series)
        NEEDS_LEGACY=true
        GPU_GEN="Maxwell v2"
        ;;
    10DE:16*|10DE:17*)  # Maxwell GM204 (some overlap)
        NEEDS_LEGACY=true
        GPU_GEN="Maxwell"
        ;;
    10DE:1B*|10DE:1C*)  # Pascal (GTX 10 series) + GP100
        NEEDS_LEGACY=true
        GPU_GEN="Pascal"
        ;;
    *)
        GPU_GEN="Turing or newer"
        ;;
esac

# =============================================================================
# Auto-switch driver if needed
# =============================================================================

if [ "$NEEDS_LEGACY" = true ]; then
    echo "=========================================" | tee -a "$LOG_FILE"
    echo "  Legacy GPU Detected: $GPU_GEN" | tee -a "$LOG_FILE"
    echo "  Switching to NVIDIA closed-source driver..." | tee -a "$LOG_FILE"
    echo "=========================================" | tee -a "$LOG_FILE"

    # Check current driver type
    CURRENT_DRIVER=$(rpm-ostree status --json 2>/dev/null | grep -o '"nvidia-open"\|"nvidia"' | head -1 || echo "unknown")

    if [ "$CURRENT_DRIVER" = "nvidia-open" ] || [ "$CURRENT_DRIVER" = "unknown" ]; then
        echo "Current driver: nvidia-open. Switching to nvidia (closed)..." | tee -a "$LOG_FILE"

        # Remove nvidia-open packages and install nvidia closed
        rpm-ostree override remove \
            kmod-nvidia-open \
            xorg-x11-drv-nvidia-open \
            --install kmod-nvidia \
            --install xorg-x11-drv-nvidia \
            || echo "WARNING: Could not auto-switch drivers via rpm-ostree." | tee -a "$LOG_FILE"

        # Configure modprobe for legacy GPU
        echo 'options nvidia NVreg_EnableGpuFirmware=0' > /etc/modprobe.d/nvidia-legacy.conf

        echo "Driver switch staged. System will apply changes on next reboot." | tee -a "$LOG_FILE"
        echo "REBOOT REQUIRED: Please reboot to apply NVIDIA driver changes." | tee -a "$LOG_FILE"

        # Create notification for user
        if command -v notify-send &> /dev/null; then
            notify-send "BamOS NVIDIA" "Đã phát hiện GPU ${GPU_GEN}. Đang chuyển sang driver phù hợp. Vui lòng khởi động lại." \
                --urgency=critical --icon=system-restart || true
        fi

        # Write a flag file to show notification on next login
        echo "GPU: $GPU_GEN | Switched to nvidia closed driver" > /etc/bamos-nvidia-switch.info
    else
        echo "Already using nvidia (closed) driver. No switch needed." | tee -a "$LOG_FILE"
    fi
else
    echo "Modern GPU detected ($GPU_GEN). Using nvidia-open driver (default)." | tee -a "$LOG_FILE"

    # Ensure nvidia-open is installed
    if ! rpm -q kmod-nvidia-open &>/dev/null; then
        echo "Installing nvidia-open driver..." | tee -a "$LOG_FILE"
        rpm-ostree install kmod-nvidia-open || true
    fi

    # Apply optimal settings for modern GPU
    echo 'options nvidia-drm modeset=1' > /etc/modprobe.d/nvidia-modeset.conf
    echo 'options nvidia-drm fbdev=1' >> /etc/modprobe.d/nvidia-modeset.conf
    echo 'options nvidia NVreg_PreserveVideoMemoryAllocations=1' >> /etc/modprobe.d/nvidia-modeset.conf
fi

# =============================================================================
# Common NVIDIA configuration
# =============================================================================

# Build initramfs with NVIDIA modules
if command -v dracut &> /dev/null; then
    dracut --force --add-drivers "nvidia nvidia_modeset nvidia_uvm nvidia_drm" 2>/dev/null || true
fi

# Enable NVIDIA services
systemctl enable nvidia-powerd.service 2>/dev/null || true
systemctl enable nvidia-persistenced.service 2>/dev/null || true

# Disable the firstboot service (only runs once)
systemctl disable bamos-nvidia-firstboot.service 2>/dev/null || true

echo "BamOS NVIDIA setup complete at $(date)" | tee -a "$LOG_FILE"
echo "=========================================" | tee -a "$LOG_FILE"
