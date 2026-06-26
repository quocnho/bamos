#!/usr/bin/env bash
set -ouex pipefail

echo "=== BamOS: DE Package Installation ==="

IMAGE_NAME="${IMAGE_NAME:-bamos}"

IS_KDE=false
IS_GNOME=false
IS_COSMIC=false
IS_NVIDIA=false
[[ "$IMAGE_NAME" == *-kde* ]] && IS_KDE=true
[[ "$IMAGE_NAME" == *-gnome* ]] && IS_GNOME=true
[[ "$IMAGE_NAME" == *-cosmic* ]] && IS_COSMIC=true
[[ "$IMAGE_NAME" == *-nvidia* ]] && IS_NVIDIA=true

# ── GNOME: Compile GSettings (picks up BamOS overrides) ──────────────────────
if [[ "$IS_GNOME" == "true" ]]; then
    glib-compile-schemas /usr/share/glib-2.0/schemas/ 2>/dev/null || true
    echo "GSettings schemas compiled for GNOME."
fi

# ── COSMIC: Add COSMIC Flatpak repo ──────────────────────────────────────────
if [[ "$IS_COSMIC" == "true" ]]; then
    flatpak remote-add --if-not-exists cosmic \
        https://apt.pop-os.org/cosmic/cosmic.flatpakrepo 2>/dev/null || true
    echo "COSMIC Flatpak repo added."
fi

# ── NVIDIA: Additional setup shared across all DEs ───────────────────────────
if [[ "$IS_NVIDIA" == "true" ]]; then
    echo "Applying NVIDIA-specific system configuration..."

    # Reinstall nouveau drivers alongside NVIDIA
    dnf5 -y reinstall --allowerasing nvidia-gpu-firmware mesa-vulkan-drivers 2>/dev/null || true

    # Symlink nvidia-ml for compatibility
    ln -sf libnvidia-ml.so.1 /usr/lib64/libnvidia-ml.so 2>/dev/null || true
fi

echo "=== BamOS: DE Package Installation Complete ==="
