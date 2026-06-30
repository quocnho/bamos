# BamOS Containerfile
# Base: Fedora Atomic Desktop (ublue-os silverblue/kinoite)
# Target: Vietnamese users with office, printing, and cultural integrations
#
# Multi-stage build supporting:
#   - bamos-gnome (Silverblue + GNOME)
#   - bamos-kde (Kinoite + KDE Plasma Win11)
#   - bamos-gnome-nvidia (GNOME + NVIDIA drivers for all GPU gens)
#   - bamos-kde-nvidia (KDE + NVIDIA drivers for all GPU gens)
#
# NVIDIA GPU Support Reference:
#   nvidia-open:  RTX 50 (Blackwell), RTX 40 (Ada), RTX 30 (Ampere), RTX 20/Turing
#   nvidia:       GTX 16/10/900/700 (Maxwell/Pascal/Volta) - closed driver
#   nvidia-legacy: GTX 600/700 (Kepler) - 470xx EOL series

ARG BASE_IMAGE="ghcr.io/ublue-os/silverblue-main"
ARG IMAGE_NAME="bamos"
ARG IMAGE_VENDOR="quocnho"
ARG IMAGE_VERSION="latest"
ARG FEDORA_VERSION="44"
ARG KERNEL_FLAVOR="main"
ARG IMAGE_COMMIT="unknown"
ARG IMAGE_BUILD_DATE=""
ARG IMAGE_REF="unknown"

# =============================================================================
# Stage 0: NVIDIA Akmods Cache (BOTH open and closed drivers)
# Both are cached so single-variant images can support all GPU generations
# =============================================================================
FROM ghcr.io/ublue-os/akmods-nvidia:${KERNEL_FLAVOR}-${FEDORA_VERSION} AS akmods-nvidia
FROM ghcr.io/ublue-os/akmods-nvidia-open:${KERNEL_FLAVOR}-${FEDORA_VERSION} AS akmods-nvidia-open

# =============================================================================
# Stage 1: Base BamOS Image (shared by all variants)
# =============================================================================
FROM ${BASE_IMAGE}:${IMAGE_VERSION} AS bamos-base

# Add image metadata
LABEL org.opencontainers.image.title="BamOS"
LABEL org.opencontainers.image.description="Vietnamese Linux Distribution"
LABEL org.opencontainers.image.vendor="${IMAGE_VENDOR}"
LABEL org.opencontainers.image.version="${IMAGE_VERSION}"
LABEL io.bamos.variant="${IMAGE_NAME}"

# =============================================================================
# 1. CORE PACKAGES
# =============================================================================

# Enable RPM Fusion repositories
RUN rpm-ostree install \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# Install core Vietnamese support packages
RUN rpm-ostree install \
    # === Vietnamese Input ===
    ibus-bamboo \
    ibus-bamboo-autostart \
    hunspell-vi \
    # === Fonts ===
    google-noto-sans-vietnamese-fonts \
    google-noto-serif-vietnamese-fonts \
    google-noto-sans-mono-vietnamese-fonts \
    # === Vietnamese Locale ===
    glibc-langpack-vi \
    # === Office & Productivity ===
    # WPS Office will be installed via script (proprietary)
    # === Printing Stack ===
    cups \
    cups-pdf \
    system-config-printer \
    # === USB Token / Smart Card Support ===
    opensc \
    pcsc-lite \
    pcsc-lite-ccid \
    pcsc-tools \
    openssl-pkcs11 \
    # === Core Utilities ===
    curl \
    wget \
    unzip \
    p7zip \
    p7zip-plugins \
    # === Firmware & Drivers ===
    fwupd \
    # === Multimedia ===
    ffmpegthumbnailer \
    # === Other ===
    @multimedia \
    @printing

# =============================================================================
# 2. SYSTEM CONFIGURATION FILES
# =============================================================================

# Copy shared system files (bamos CLI, libexec scripts, shell aliases, fastfetch, systemd)
COPY system_files/shared/ /

# Make all bamos scripts executable
RUN chmod +x /usr/bin/bamos && \
    find /usr/libexec/bamos -type f -exec chmod +x {} \;

# Copy font configuration (Vietnamese font aliases, MS replacements, rendering)
COPY system_files/fonts/66-bamos-vietnamese.conf /etc/fonts/conf.d/66-bamos-vietnamese.conf

# Copy GNOME GSsettings override (RakuOS-inspired theme, extensions, keybindings)
COPY system_files/shared/usr/share/glib-2.0/schemas/zz-bamos-gnome.gschema.override /usr/share/glib-2.0/schemas/

# Compile GSsettings
RUN glib-compile-schemas /usr/share/glib-2.0/schemas/

# Copy sudoers for passwordless package management
COPY system_files/shared/etc/sudoers.d/ /etc/sudoers.d/
RUN chown root:root /etc/sudoers.d/bamos-software && \
    chmod 0440 /etc/sudoers.d/bamos-software

# Copy KDE configuration files
COPY system_files/kde/ /etc/skel/.config/

# Copy WPS Office configuration
COPY system_files/office/wps-config/ /etc/skel/.config/Kingsoft/

# Copy Web App definitions
COPY system_files/webapps/ /usr/share/bamos/webapps/

# =============================================================================
# 3. BRANDING
# =============================================================================

# Copy logo
COPY branding/logo-bamos.svg /usr/share/bamos/branding/logo-bamos.svg
COPY branding/logo-bamos.svg /usr/share/pixmaps/bamos-logo.svg

# Plymouth boot splash theme
COPY branding/plymouth/ /usr/share/plymouth/themes/bamos/

# =============================================================================
# 4. SCRIPTS
# =============================================================================

COPY build_files/ /usr/libexec/bamos/
RUN chmod +x /usr/libexec/bamos/*.sh

# =============================================================================
# 5. POST-INSTALL SCRIPTS
# =============================================================================

# Run first-boot setup scripts
RUN /usr/libexec/bamos/setup-vn-input.sh
RUN /usr/libexec/bamos/setup-fonts.sh
RUN /usr/libexec/bamos/setup-printing.sh

# Install BamOS Portal (GTK4 first-boot setup wizard)
RUN /usr/libexec/bamos/install-portal.sh || echo "BamOS Portal setup deferred"

# Install BamOS Store (GNOME app store)
RUN /usr/libexec/bamos/install-store.sh || echo "BamOS Store setup deferred"

# Apply branding (logo, Plymouth, OS release)
RUN /usr/libexec/bamos/branding.sh || echo "Branding setup deferred"

# Setup WPS Office (downloaded during build to keep image reproducible)
# Note: WPS Office is proprietary; users accept license during first run
RUN /usr/libexec/bamos/install-wps.sh

# Setup Zalo via Wine
RUN /usr/libexec/bamos/setup-zalo.sh || echo "Zalo setup deferred to first boot"

# Setup USB Token libraries
RUN /usr/libexec/bamos/setup-token.sh

# =============================================================================
# 7. KERNEL & PERFORMANCE OPTIMIZATION (CachyOS-inspired)
# =============================================================================

# Apply CachyOS performance tuning (scx schedulers, ananicy, BBR, IO scheduler, sysctl)
# Uses uBlue kernel + CachyOS userspace tuning for maximum stability
RUN /usr/libexec/bamos/kernel-optimize.sh || echo "Kernel optimization deferred"

# =============================================================================
# 6. ADDITIONAL KERNEL MODULES (Bazzite pattern)
# =============================================================================

# Install community kernel modules: xone (Xbox), xpadneo (Xbox BT), broadcom-wl, v4l2loopback
RUN /usr/libexec/bamos/install-kmods.sh || echo "Some kmods deferred"

# =============================================================================
# 7. IMAGE INFO (Bazzite pattern)
# =============================================================================

# Generate OCI metadata and image info JSON
RUN IMAGE_NAME="${IMAGE_NAME}" IMAGE_VENDOR="${IMAGE_VENDOR}" \
    IMAGE_VERSION="${IMAGE_VERSION}" BASE_IMAGE="${BASE_IMAGE}" \
    /usr/libexec/bamos/image-info.sh

# =============================================================================
# 8. CLEANUP & FINALIZE (Bazzite finalize pattern)
# =============================================================================

# Run Bazzite-style finalize: migrate passwd/group, clean locks, temp files, cache
RUN /usr/libexec/bamos/finalize.sh

# Update font cache after all fonts installed
RUN fc-cache -fv

# =============================================================================
# 9. FINAL SYSTEM SETUP
# =============================================================================

# Set system locale defaults
RUN localedef -i vi_VN -f UTF-8 vi_VN.UTF-8

# Wire up zshrc.d fragment sourcing
RUN mkdir -p /etc/zshrc.d && \
    if ! grep -q 'zshrc.d' /etc/zshrc 2>/dev/null; then \
        echo '' >> /etc/zshrc && \
        echo '# Source BamOS zsh configuration fragments' >> /etc/zshrc && \
        echo 'for _f in /etc/zshrc.d/*.zsh; do [[ -r "$_f" ]] && source "$_f"; done' >> /etc/zshrc && \
        echo 'unset _f' >> /etc/zshrc; \
    fi

# Link fastfetch system config
RUN mkdir -p /etc/fastfetch && \
    ln -sf /usr/share/fastfetch/presets/bamos/bamos-fastfetch.jsonc /etc/fastfetch/config.jsonc

# =============================================================================
# Copy Flatpak fixes (per-app post-install hooks: Firefox, StreamController)
COPY system_files/shared/usr/libexec/bamos/internal/flatpak-fixes/ /usr/libexec/bamos/internal/flatpak-fixes/

# Copy Fish shell aliases
COPY system_files/shared/etc/fish/conf.d/ /etc/fish/conf.d/

# Copy Secure Boot certificate
COPY branding/bamos-mok.cer /usr/share/bamos/secureboot/bamos-sb.der

# =============================================================================
# Enable system services (RakuOS-inspired maintenance timers)
# =============================================================================

RUN systemctl enable bamos-cache-clean.timer && \
    systemctl enable flatpak-cleanup.timer && \
    systemctl enable flatpak-repair.timer && \
    systemctl enable podman-prune.timer && \
    systemctl enable bamos-setup.service && \
    systemctl enable bamos-flatpak-watcher.service && \
    systemctl enable bamos-updater.timer && \
    systemctl enable bamos-enroll-secureboot.service || true

# Enable user services
RUN systemctl --global enable bamos-user.service || true

# Set default Plymouth theme
RUN plymouth-set-default-theme bamos -R || true

# Copy ISO/USB GRUB configuration
COPY branding/iso-grub.cfg /usr/share/bamos/iso-grub.cfg

# Copy live environment os-release
COPY branding/live-os-release /usr/share/bamos/live-os-release

# Copy BamOS Portal desktop entry
COPY system_files/shared/usr/share/applications/io.bamos.Portal.desktop /usr/share/applications/io.bamos.Portal.desktop

# Copy BamOS Portal metainfo
COPY system_files/shared/usr/share/metainfo/io.bamos.Portal.metainfo.xml /usr/share/metainfo/io.bamos.Portal.metainfo.xml

# Copy BamOS Portal configuration
COPY system_files/shared/usr/share/bamos/portal/portal.yml /usr/share/bamos/portal/portal.yml

# =============================================================================
# Stage 2: NVIDIA Variant (derived from base BamOS)
# Single variant supports ALL GPU generations via first-boot auto-detection
# =============================================================================

FROM bamos-base AS bamos-nvidia

ARG IMAGE_NAME="${IMAGE_NAME:-bamos-nvidia}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR:-quocnho}"
ARG VERSION_TAG="${VERSION_TAG}"
ARG VERSION_PRETTY="${VERSION_PRETTY}"
ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-kinoite}"

LABEL org.opencontainers.image.title="BamOS NVIDIA"
LABEL org.opencontainers.image.description="BamOS with NVIDIA GPU drivers (auto-detect: open + closed)"
LABEL io.bamos.nvidia.flavor="auto-detect"

# Copy NVIDIA system files
COPY system_files/nvidia/shared/ /

# Remove open-source nouveau driver (conflicts with NVIDIA proprietary)
RUN rpm-ostree override remove \
    xorg-x11-drv-nouveau \
    || true

# =============================================================================
# Install NVIDIA Open Driver (default for RTX 20+ GPUs)
# =============================================================================

RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=akmods-nvidia-open,src=/rpms,dst=/tmp/rpms/nvidia-open \
    --mount=type=tmpfs,dst=/tmp \
    echo "Installing NVIDIA open driver (default for Turing+ GPUs)..." && \
    IMAGE_NAME="${BASE_IMAGE_NAME}" \
    AKMODNV_PATH="/tmp/rpms/nvidia-open" \
    MULTILIB=1 \
    /tmp/rpms/nvidia-open/ublue-os/nvidia-install.sh && \
    rm -f /usr/share/vulkan/icd.d/nouveau_icd.*.json && \
    ln -sf libnvidia-ml.so.1 /usr/lib64/libnvidia-ml.so

# =============================================================================
# Also cache NVIDIA Closed Driver RPMs (for Maxwell/Pascal legacy GPUs)
# These are staged in /opt/bamos/nvidia-closed/ for first-boot switching
# =============================================================================

RUN --mount=type=cache,dst=/var/cache \
    --mount=type=bind,from=akmods-nvidia,src=/rpms,dst=/tmp/rpms/nvidia \
    --mount=type=tmpfs,dst=/tmp \
    echo "Caching NVIDIA closed driver RPMs for legacy GPU auto-switching..." && \
    mkdir -p /opt/bamos/nvidia-closed/ && \
    cp -r /tmp/rpms/nvidia/kmods/*.rpm /opt/bamos/nvidia-closed/ 2>/dev/null || true && \
    cp -r /tmp/rpms/nvidia/ublue-os/*.rpm /opt/bamos/nvidia-closed/ 2>/dev/null || true && \
    echo "Cached $(ls /opt/bamos/nvidia-closed/*.rpm 2>/dev/null | wc -l) closed-driver RPMs"

# =============================================================================
# Install NVIDIA userspace tools
# =============================================================================

RUN rpm-ostree install \
    egl-wayland \
    egl-wayland2 \
    nvidia-settings \
    nvidia-persistenced \
    || echo "Some NVIDIA packages deferred to runtime"

# Install NVIDIA Container Toolkit for GPU passthrough to containers
RUN curl -sL https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo \
    -o /etc/yum.repos.d/nvidia-container-toolkit.repo && \
    rpm-ostree install nvidia-container-toolkit || true

# =============================================================================
# First-boot auto-detection setup
# =============================================================================

# Make scripts executable
RUN chmod +x /usr/libexec/bamos/nvidia-setup.sh && \
    chmod +x /usr/libexec/bamos/nvidia-firstboot-setup.sh

# Create systemd service for first-boot NVIDIA auto-detection
RUN printf '[Unit]\nDescription=BamOS NVIDIA First-Boot GPU Detection\nAfter=network.target\nBefore=display-manager.service\n\n[Service]\nType=oneshot\nExecStart=/usr/libexec/bamos/nvidia-firstboot-setup.sh\nRemainAfterExit=yes\nTimeoutStartSec=120\n\n[Install]\nWantedBy=multi-user.target\n' > /etc/systemd/system/bamos-nvidia-firstboot.service && \
    systemctl enable bamos-nvidia-firstboot.service

# =============================================================================
# Finalize NVIDIA image
# =============================================================================

RUN rpm-ostree cleanup -m && \
    ostree container commit

# Lint check
RUN --mount=type=tmpfs,target=/run --network=none bootc container lint || true
