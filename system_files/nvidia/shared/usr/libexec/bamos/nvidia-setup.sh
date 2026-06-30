#!/bin/bash
# nvidia-setup.sh - BamOS NVIDIA Driver Setup & Management
# Handles installation, detection, and configuration for all NVIDIA GPU generations
# Supports: Kepler (600/700), Maxwell (700/900), Pascal (10), Volta, Turing (16/20),
#           Ampere (30), Ada Lovelace (40), Blackwell (50)

set -e

echo "============================================="
echo "  BamOS NVIDIA Driver Setup & Management"
echo "============================================="

# =============================================================================
# GPU Detection
# =============================================================================

detect_nvidia_gpu() {
    if command -v lspci &> /dev/null; then
        lspci -nn | grep -i "nvidia" || true
    fi
}

# Determine GPU generation from PCI ID
detect_gpu_generation() {
    local pci_id="$1"
    case "$pci_id" in
        *"10DE:2"* | *"10DE:26"* | *"10DE:27"* | *"10DE:28"* | *"10DE:29"*)
            echo "blackwell" ;;    # RTX 50 series
        *"10DE:22"* | *"10DE:23"* | *"10DE:24"* | *"10DE:25"*)
            echo "ada_lovelace" ;; # RTX 40 series
        *"10DE:24"* | *"10DE:25"*)
            echo "ampere" ;;       # RTX 30 series
        *"10DE:1E"* | *"10DE:1F"* | *"10DE:21"*)
            echo "turing" ;;       # RTX 20 series, GTX 16 series
        *"10DE:1B"* | *"10DE:1C"* | *"10DE:1D"*)
            echo "volta" ;;        # Titan V, Quadro GV100
        *"10DE:1B"* | *"10DE:1C"*)
            echo "pascal" ;;       # GTX 10 series
        *"10DE:13"* | *"10DE:14"* | *"10DE:15"* | *"10DE:16"* | *"10DE:17"*)
            echo "maxwell_v2" ;;   # GTX 900 series
        *"10DE:11"* | *"10DE:12"*)
            echo "maxwell_v1" ;;   # GTX 700 series (Maxwell)
        *"10DE:0F"* | *"10DE:10"*)
            echo "kepler" ;;       # GTX 600/700 series (Kepler)
        *)
            echo "unknown" ;;
    esac
}

# =============================================================================
# Driver Type Selection
# =============================================================================

# NVIDIA Driver Types supported:
# 1. nvidia-open  - Open GPU kernel modules (Turing+/RTX 20+, GTX 16+)
# 2. nvidia       - Closed-source driver (Maxwell+, older GPUs)
#
# Legacy GPU Support (Kepler GTX 600/700):
# Kepler GPUs require nvidia-470xx legacy driver series
# Last supported driver: 470.xx (EOL, security fixes only from distro)

check_driver_compatibility() {
    local gen="$1"
    case "$gen" in
        blackwell|ada_lovelace)
            echo "nvidia-open"  # REQUIRED - only open driver supports these
            ;;
        ampere|turing|volta)
            echo "nvidia-open"  # Recommended - open driver works best
            ;;
        pascal|maxwell_v2|maxwell_v1)
            echo "nvidia"       # REQUIRED - only closed driver supports these
            ;;
        kepler)
            echo "nvidia-legacy" # Legacy 470xx series
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# =============================================================================
# NVIDIA Configuration
# =============================================================================

configure_nvidia_settings() {
    echo "Configuring NVIDIA settings for Wayland..."

    # Enable DRM modeset (required for Wayland)
    echo 'options nvidia-drm modeset=1' > /etc/modprobe.d/nvidia-modeset.conf
    echo 'options nvidia-drm fbdev=1' >> /etc/modprobe.d/nvidia-modeset.conf

    # Preserve video memory allocations for smoother transitions
    echo 'options nvidia NVreg_PreserveVideoMemoryAllocations=1' >> /etc/modprobe.d/nvidia-modeset.conf
    echo 'options nvidia NVreg_TemporaryFilePath=/var/tmp' >> /etc/modprobe.d/nvidia-modeset.conf

    # Enable nvidia-powerd service for dynamic power management
    systemctl enable nvidia-powerd.service 2>/dev/null || true

    # Enable nvidia-persistenced for persistence mode
    systemctl enable nvidia-persistenced.service 2>/dev/null || true

    echo "NVIDIA configuration applied."
}

# Configure for legacy GPUs (Kepler/Maxwell V1)
configure_legacy_nvidia() {
    echo "Configuring for legacy NVIDIA GPU..."

    # Disable GSP firmware (not supported on legacy GPUs)
    echo 'options nvidia NVreg_EnableGpuFirmware=0' >> /etc/modprobe.d/nvidia-modeset.conf

    # Older GPUs may need X11-specific settings
    mkdir -p /etc/X11/xorg.conf.d/
    cat > /etc/X11/xorg.conf.d/10-nvidia-legacy.conf << 'EOF'
Section "Device"
    Identifier "NVIDIA Legacy"
    Driver "nvidia"
    Option "NoLogo" "1"
    Option "Coolbits" "28"
EndSection
EOF

    echo "Legacy NVIDIA GPU configuration applied."
}

# =============================================================================
# Main Setup
# =============================================================================

echo ""
echo "Detecting NVIDIA GPU..."
detect_nvidia_gpu

# Check if NVIDIA GPU is present
if ! lspci -nn | grep -qi "nvidia"; then
    echo "No NVIDIA GPU detected. Skipping NVIDIA setup."
    echo "If you have an NVIDIA GPU, ensure it is properly connected."
    exit 0
fi

# Get the first NVIDIA PCI ID for detection
NVIDIA_PCI_ID=$(lspci -nn | grep -i "nvidia" | head -1 | grep -oP '\[\K[0-9A-F]{4}:[0-9A-F]{4}(?=\])' || echo "")

if [ -n "$NVIDIA_PCI_ID" ]; then
    GPU_GEN=$(detect_gpu_generation "$NVIDIA_PCI_ID")
    echo "Detected GPU Generation: $GPU_GEN"
    DRIVER_TYPE=$(check_driver_compatibility "$GPU_GEN")
    echo "Recommended Driver Type: $DRIVER_TYPE"
else
    echo "Could not determine GPU generation."
    GPU_GEN="unknown"
fi

# Apply NVIDIA configuration
configure_nvidia_settings

# Apply legacy configuration if needed
case "$GPU_GEN" in
    kepler|maxwell_v1)
        configure_legacy_nvidia
        echo ""
        echo "============================================="
        echo "  IMPORTANT: Legacy GPU Detected!"
        echo "============================================="
        echo "Your GPU ($GPU_GEN) requires the legacy NVIDIA driver."
        echo "This driver is EOL (End of Life) and may have limitations:"
        echo "  - No Wayland support (X11 only)"
        echo "  - Security fixes only from distribution"
        echo "  - Limited CUDA/OpenCL support"
        echo ""
        echo "For best experience, consider upgrading to a newer GPU."
        echo "============================================="
        ;;
esac

# Build initramfs to include NVIDIA modules
if command -v dracut &> /dev/null; then
    echo "Rebuilding initramfs with NVIDIA modules..."
    dracut --force --add-drivers "nvidia nvidia_modeset nvidia_uvm nvidia_drm" || true
fi

echo ""
echo "============================================="
echo "  NVIDIA Setup Complete!"
echo "============================================="
echo ""
echo "Useful commands:"
echo "  nvidia-smi          - Show GPU status and driver version"
echo "  nvidia-settings     - NVIDIA control panel"
echo "  nvtop               - GPU process monitor"
echo "  just setup-nvidia   - Re-run this setup"
echo ""

# Check if Wayland is properly configured
if [ -f /etc/modprobe.d/nvidia-modeset.conf ]; then
    echo "✓ NVIDIA DRM modeset enabled (Wayland ready)"
else
    echo "✗ NVIDIA DRM modeset NOT configured"
fi
