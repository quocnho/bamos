# Justfile for BamOS
# Provides convenient commands for building and managing BamOS locally

# Display help information
default:
    @just --list

# Build BamOS GNOME variant locally
build-gnome BASE_IMAGE="ghcr.io/ublue-os/silverblue-main:latest" TAG="bamos-gnome:local":
    podman build \
        -f Containerfile \
        --build-arg BASE_IMAGE={{ BASE_IMAGE }} \
        --build-arg IMAGE_NAME=bamos-gnome \
        -t {{ TAG }} .

# Build BamOS KDE variant locally
build-kde BASE_IMAGE="ghcr.io/ublue-os/kinoite-main:latest" TAG="bamos-kde:local":
    podman build \
        -f Containerfile \
        --build-arg BASE_IMAGE={{ BASE_IMAGE }} \
        --build-arg IMAGE_NAME=bamos-kde \
        -t {{ TAG }} .

# Build all variants
build-all:
    just build-gnome
    just build-kde
    just build-gnome-nvidia
    just build-kde-nvidia

# Build GNOME variant with NVIDIA (auto-detect: open for RTX 20+, closed for legacy GPUs)
build-gnome-nvidia:
    podman build \
        -f Containerfile \
        --target bamos-nvidia \
        --build-arg BASE_IMAGE=ghcr.io/ublue-os/silverblue-main:latest \
        --build-arg BASE_IMAGE_NAME=silverblue \
        --build-arg IMAGE_NAME=bamos-gnome-nvidia \
        -t bamos-gnome-nvidia:local .

# Build KDE variant with NVIDIA (auto-detect: open for RTX 20+, closed for legacy GPUs)
build-kde-nvidia:
    podman build \
        -f Containerfile \
        --target bamos-nvidia \
        --build-arg BASE_IMAGE=ghcr.io/ublue-os/kinoite-main:latest \
        --build-arg BASE_IMAGE_NAME=kinoite \
        --build-arg IMAGE_NAME=bamos-kde-nvidia \
        -t bamos-kde-nvidia:local .

# Run a shell inside the built GNOME image
shell-gnome:
    podman run --rm -it bamos-gnome:local /bin/bash

# Run a shell inside the built KDE image
shell-kde:
    podman run --rm -it bamos-kde:local /bin/bash

# Validate Containerfile syntax
validate:
    podman build --check . -f Containerfile

# Clean up local build cache
clean:
    podman image prune -f
    podman builder prune -f

# Setup Vietnamese input method (run on installed system)
setup-input:
    @echo "Setting up Vietnamese input method..."
    /usr/libexec/bamos/ibus-bamboo-setup.sh

# Setup WPS Office (run on installed system)
setup-wps:
    @echo "Setting up WPS Office..."
    /usr/libexec/bamos/install-wps.sh

# Setup Zalo (run on installed system)
setup-zalo:
    @echo "Setting up Zalo..."
    /usr/libexec/bamos/setup-zalo.sh

# Setup USB Token / Digital Signature
setup-token:
    @echo "Setting up USB Token libraries..."
    /usr/libexec/bamos/setup-token.sh

# Setup printers
setup-printer:
    @echo "Setting up printer support..."
    sudo /usr/libexec/bamos/setup-printing.sh

# Setup Vietnamese fonts
setup-fonts:
    @echo "Configuring Vietnamese fonts..."
    /usr/libexec/bamos/setup-fonts.sh

# Install Vietnamese proprietary fonts (VNI, VnTime, MS fonts from Windows partition)
setup-fonts-proprietary:
    @echo "Installing Vietnamese proprietary fonts..."
    bash /usr/libexec/bamos/setup-fonts-proprietary.sh

# Download and install Microsoft Core Fonts
setup-fonts-ms:
    @echo "Installing Microsoft Core Fonts..."
    bash /usr/libexec/bamos/setup-fonts-ms.sh

# Install all fonts (open + proprietary + MS)
setup-fonts-all: setup-fonts setup-fonts-proprietary setup-fonts-ms
    @echo "All fonts installed!"

# Run all setup scripts (for fresh install)
setup-all: setup-input setup-fonts setup-printer setup-wps setup-zalo setup-token
    @echo "All setup complete!"

# Install additional kernel modules (Xbox controllers, Broadcom WiFi, virtual camera)
install-kmods:
    @echo "Installing additional kernel modules..."
    sudo /usr/libexec/bamos/install-kmods.sh
    @echo "Reboot to load new modules."

# Setup Ollama for local AI
setup-ollama:
    @echo "Setting up Ollama..."
    /usr/libexec/bamos/setup-ollama

# Setup Lossless Scaling Frame Gen
setup-lsfg-vk:
    @echo "Setting up LSFG Vulkan..."
    /usr/libexec/bamos/setup-lsfg-vk

# Generate Flatpak CLI wrappers
flatpak-wrappers:
    @echo "Generating Flatpak CLI wrappers..."
    /usr/libexec/bamos/bamos-flatpak-wrapper-gen

# Install BamOS Portal (GTK4 first-boot setup wizard)
install-portal:
    @echo "Installing BamOS Portal..."
    sudo /usr/libexec/bamos/install-portal.sh

# Install BamOS Store (GNOME app store)
install-store:
    @echo "Installing BamOS Store..."
    sudo /usr/libexec/bamos/install-store.sh

# Launch BamOS Portal
portal:
    @echo "Launching BamOS Portal..."
    /usr/libexec/bamos/bamos-portal.py

# Launch BamOS Store (if installed)
store:
    flatpak run io.github.bazaar_org.bazaar || bamstore || echo "BamOS Store not installed. Run: just install-store"

# Update system (rpm-ostree)
update:
    rpm-ostree update

# Rebase to a different BamOS image
rebase IMAGE="bamos-gnome:latest":
    sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/quocnho/{{ IMAGE }}

# Rollback to previous deployment
rollback:
    rpm-ostree rollback

# Rebase to BamOS NVIDIA variant
rebase-nvidia BASE="bamos-gnome-nvidia:latest":
    sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/quocnho/{{ BASE }}

# =============================================================================
# NVIDIA GPU Management
# =============================================================================

# Setup/configure NVIDIA driver (run on installed system)
setup-nvidia:
    @echo "Setting up NVIDIA drivers..."
    sudo /usr/libexec/bamos/nvidia-setup.sh

# Switch to NVIDIA closed-source driver (for Maxwell/Pascal legacy GPUs)
# This layers the closed driver via rpm-ostree and requires a reboot
switch-nvidia-legacy:
    @echo "Switching to NVIDIA closed-source driver for legacy GPUs..."
    @echo "This will remove nvidia-open and install nvidia (closed)."
    @echo "Reboot required after completion."
    sudo rpm-ostree override remove kmod-nvidia-open xorg-x11-drv-nvidia-open \
        --install kmod-nvidia \
        --install xorg-x11-drv-nvidia
    @echo ""
    @echo "Done! Please reboot to apply changes: systemctl reboot"

# Switch to NVIDIA open driver (for Turing/RTX 20+ GPUs)
# This layers the open driver via rpm-ostree and requires a reboot
switch-nvidia-open:
    @echo "Switching to NVIDIA open-source kernel driver for modern GPUs..."
    @echo "This will remove nvidia (closed) and install nvidia-open."
    @echo "Reboot required after completion."
    sudo rpm-ostree override remove kmod-nvidia xorg-x11-drv-nvidia \
        --install kmod-nvidia-open \
        --install xorg-x11-drv-nvidia-open
    @echo ""
    @echo "Done! Please reboot to apply changes: systemctl reboot"

# Show NVIDIA GPU information
nvidia-info:
    @echo "=== NVIDIA GPU Information ==="
    nvidia-smi || echo "nvidia-smi not found. Run 'just setup-nvidia' first."
    @echo ""
    @echo "=== GPU Details ==="
    lspci -nn | grep -i nvidia || echo "No NVIDIA GPU detected in lspci"
    @echo ""
    @echo "=== Driver Version ==="
    modinfo nvidia | grep version || echo "NVIDIA module not loaded"

# Monitor NVIDIA GPU (requires nvtop)
nvidia-monitor:
    nvtop || echo "Install nvtop: sudo rpm-ostree install nvtop"

# Check NVIDIA Wayland support
nvidia-wayland-check:
    @echo "=== Wayland NVIDIA Status ==="
    @if [ -f /etc/modprobe.d/nvidia-modeset.conf ]; then
        echo "✓ NVIDIA modeset enabled"
        grep modeset /etc/modprobe.d/nvidia-modeset.conf || true
    else
        echo "✗ NVIDIA modeset NOT configured"
    fi
    @echo ""
    @if pgrep -x "gnome-shell" > /dev/null || pgrep -x "kwin_wayland" > /dev/null; then
        echo "✓ Running Wayland session"
    else
        echo "⚠ Not a Wayland session (or cannot detect)"
    fi

# Detect NVIDIA GPU generation
nvidia-detect-gen:
    @echo "Detecting NVIDIA GPU generation..."
    @GPU_PCI=$$(lspci -nn | grep -i nvidia | head -1 | grep -oP '\[\K[0-9A-F]{4}:[0-9A-F]{4}(?=\])' || echo ""); \
    if [ -n "$$GPU_PCI" ]; then \
        echo "GPU PCI ID: $$GPU_PCI"; \
        case "$$GPU_PCI" in \
            *"10DE:2"* | *"10DE:26"* | *"10DE:27"* | *"10DE:28"*) echo "Generation: Blackwell (RTX 50 series) - Use nvidia-open driver";; \
            *"10DE:22"* | *"10DE:23"* | *"10DE:24"* | *"10DE:25"*) echo "Generation: Ada Lovelace (RTX 40 series) - Use nvidia-open driver";; \
            *"10DE:24"*|*"10DE:25"*) echo "Generation: Ampere (RTX 30 series) - Use nvidia-open driver";; \
            *"10DE:1E"* | *"10DE:1F"* | *"10DE:21"*) echo "Generation: Turing (RTX 20/GTX 16 series) - Use nvidia-open driver";; \
            *"10DE:1B"*|*"10DE:1C"*|*"10DE:1D"*) echo "Generation: Volta/Pascal (GTX 10 series) - Use nvidia (closed) driver";; \
            *"10DE:13"* | *"10DE:14"* | *"10DE:15"*) echo "Generation: Maxwell v2 (GTX 900 series) - Use nvidia (closed) driver";; \
            *"10DE:11"* | *"10DE:12"*) echo "Generation: Maxwell v1 (GTX 700 series) - Use nvidia (closed) driver";; \
            *"10DE:0F"* | *"10DE:10"*) echo "Generation: Kepler (GTX 600/700) - Legacy 470xx only, NO Wayland";; \
            *) echo "Generation: Unknown - Check docs/NVIDIA-COMPATIBILITY.md";;
        esac; \
    else \
        echo "No NVIDIA GPU detected."; \
    fi

# Enroll Secure Boot key for NVIDIA modules
enroll-secure-boot-key:
    @echo "Enrolling Secure Boot key for NVIDIA kernel modules..."
    sudo mokutil --timeout -1
    sudo mokutil --import /etc/pki/akmods/certs/public_key.der
    @echo "Reboot and enroll the key in the MOK Manager."
    @echo "Password: universalblue"

# Check current deployment status
status:
    rpm-ostree status

# Preview what changed in pending deployment
changes:
    rpm-ostree db diff

# Enroll Secure Boot key
enroll-secure-boot-key:
    sudo mokutil --timeout -1
    sudo mokutil --import /etc/pki/akmods/certs/public_key.der
    @echo "Reboot and enroll the key in the MOK Manager."
    @echo "Password: universalblue"
