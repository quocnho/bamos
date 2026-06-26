#!/usr/bin/env bash
set -ouex pipefail

echo "=== BamOS Build Setup ==="

# ── Detect variant ────────────────────────────────────────────────────────────
# IMAGE_NAME is set by BlueBuild from recipe name, e.g. "bamos-kde-nvidia"
IMAGE_NAME="${IMAGE_NAME:-bamos}"
IS_NVIDIA=false
[[ "$IMAGE_NAME" == *-nvidia ]] && IS_NVIDIA=true

# ── Enable RPM Fusion ─────────────────────────────────────────────────────────
FEDORA_VERSION=$(rpm -E %fedora)
dnf5 -y install dnf5-plugins
dnf5 -y install \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VERSION}.noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VERSION}.noarch.rpm

# ── Enable COPR repos ─────────────────────────────────────────────────────────
for copr in \
    bieszczaders/kernel-cachyos \
    bieszczaders/kernel-cachyos-addons \
    atim/starship \
    che/nerd-fonts; do
    dnf5 -y copr enable "$copr" fedora-${FEDORA_VERSION}-x86_64
done

# ── Swap kernel to CachyOS ────────────────────────────────────────────────────
if rpm -q kernel 2>/dev/null || rpm -q kernel-core 2>/dev/null; then
    KERNEL_PKGS="kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra kernel-tools kernel-tools-libs"
    dnf5 -y remove --no-autoremove $KERNEL_PKGS 2>/dev/null || true
fi
dnf5 -y --setopt=tsflags=noscripts install kernel-cachyos kernel-cachyos-devel-matched

# ── Install core packages ─────────────────────────────────────────────────────
dnf5 -y install \
    ananicy-cpp \
    cachyos-ananicy-rules \
    cachyos-settings \
    bore-sysctl \
    scx-scheds \
    scx-tools \
    gamemode \
    gamemode.i686 \
    mangohud \
    mangohud.i686 \
    vkBasalt \
    vkBasalt.i686 \
    dkms \
    akmods \
    micro \
    starship \
    fastfetch \
    bat \
    ripgrep \
    htop \
    btop \
    neovim \
    git \
    distrobox \
    podman \
    podman-compose \
    flatpak \
    libxcrypt-compat \
    rsync \
    fuse \
    squashfuse \
    lm_sensors \
    unzip \
    python3-pip \
    python3-setuptools \
    appstream \
    appstream-data \
    fwupd \
    ffmpeg \
    mesa-dri-drivers.i686 \
    mesa-va-drivers.i686 \
    mesa-vulkan-drivers.i686 \
    mesa-libEGL.i686 \
    mesa-libGL.i686 \
    inotify-tools \
    sqlite3 \
    openssl \
    libnotify \
    nerd-fonts

# ── Install NVIDIA packages (if NVIDIA variant) ───────────────────────────────
if [[ "$IS_NVIDIA" == "true" ]]; then
    dnf5 -y install \
        akmod-nvidia \
        xorg-x11-drv-nvidia-cuda \
        nvidia-vaapi-driver \
        nvidia-persistenced

    systemctl enable nvidia-powerd.service 2>/dev/null || true
    systemctl enable nvidia-persistenced.service 2>/dev/null || true
    echo "NVIDIA driver packages installed."
fi

# ── Enable Flathub ────────────────────────────────────────────────────────────
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# ── Disable/mask unnecessary services ─────────────────────────────────────────
systemctl disable flatpak-add-fedora-repos.service 2>/dev/null || true
systemctl mask akmods-keygen@akmods-keygen.service 2>/dev/null || true
systemctl mask systemd-remount-fs.service 2>/dev/null || true

# ── Enable useful services ────────────────────────────────────────────────────
systemctl enable flatpak-cleanup.timer 2>/dev/null || true
systemctl enable rpm-ostree-clean-metadata.timer 2>/dev/null || true
systemctl enable rpm-ostree-clean-deployments.timer 2>/dev/null || true
systemctl enable podman-prune.timer 2>/dev/null || true

echo "=== BamOS Build Setup Complete ==="
