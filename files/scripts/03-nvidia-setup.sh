#!/usr/bin/env bash
set -ouex pipefail

echo "=== BamOS NVIDIA Setup ==="

IMAGE_NAME="${IMAGE_NAME:-bamos}"

# Only run on NVIDIA variants
if [[ "$IMAGE_NAME" != *-nvidia ]]; then
    echo "Not an NVIDIA variant — skipping."
    exit 0
fi

# NVIDIA driver and environment setup
echo "Configuring NVIDIA-specific settings..."

# Add NVIDIA module to dracut
echo "Adding NVIDIA modules to initramfs..."
cat > /etc/dracut.conf.d/nvidia.conf << 'EOF'
add_drivers+=" nvidia nvidia_modeset nvidia_uvm nvidia_drm "
force_drivers+=" nvidia nvidia_modeset nvidia_uvm nvidia_drm "
EOF

# Create NVIDIA X11 config
mkdir -p /etc/X11/xorg.conf.d
cat > /etc/X11/xorg.conf.d/00-nvidia.conf << 'EOF'
Section "OutputClass"
    Identifier "nvidia"
    MatchDriver "nvidia-drm"
    Driver "nvidia"
    Option "AllowEmptyInitialConfiguration"
    Option "PrimaryGPU" "yes"
    ModulePath "/usr/lib64/nvidia/xorg"
    ModulePath "/usr/lib64/xorg/modules"
EndSection
EOF

# Enable NVIDIA suspend/resume services
systemctl enable nvidia- suspend.service 2>/dev/null || true
systemctl enable nvidia-resume.service 2>/dev/null || true
systemctl enable nvidia-hibernate.service 2>/dev/null || true

# Set kernel module parameters
cat > /etc/modprobe.d/nvidia-modeset.conf << 'EOF'
options nvidia_drm modeset=1 fbdev=1
options nvidia NVreg_EnableMSI=1
options nvidia NVreg_OpenRmEnableUnsupportedGpus=1
EOF

# Enable Wayland with NVIDIA
cat > /etc/environment << 'EOF'
GBM_BACKEND=nvidia-drm
__GLX_VENDOR_LIBRARY_NAME=nvidia
WLR_NO_HARDWARE_CURSORS=1
EOF

echo "=== BamOS NVIDIA Setup Complete ==="
