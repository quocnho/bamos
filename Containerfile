# BamOS Containerfile
# Base: Fedora Atomic Desktop (ublue-os silverblue/kinoite)
# Target: Vietnamese users with office, printing, and cultural integrations
#
# Multi-stage build:
#   Stage 1: bamos-base        — Common packages (NO input method)
#   Stage 2: bamos-gnome       — base + ibus-unikey (GNOME)
#   Stage 3: bamos-kde         — base + fcitx5-unikey (KDE)
#   Stage 4: bamos-nvidia-gnome — bamos-gnome + NVIDIA (GNOME-NVIDIA)
#   Stage 5: bamos-nvidia-kde  — bamos-kde + NVIDIA (KDE-NVIDIA)
#
# NVIDIA: RPM Fusion (not akmods cache — Fedora 44 akmods not yet published)

ARG BASE_IMAGE="ghcr.io/ublue-os/silverblue-main"
ARG IMAGE_NAME="bamos"
ARG IMAGE_VENDOR="quocnho"
ARG IMAGE_VERSION="latest"
ARG FEDORA_VERSION="44"
ARG IMAGE_COMMIT="unknown"
ARG IMAGE_BUILD_DATE=""
ARG IMAGE_REF="unknown"

# =============================================================================
# Stage 1: Base BamOS Image (shared by all variants, NO input method)
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

# Disable updates-archive repo (unreachable in container builds)
RUN sed -i 's/enabled=1/enabled=0/' /etc/yum.repos.d/fedora-updates-archive.repo 2>/dev/null || true

# Enable RPM Fusion repositories
RUN rpm-ostree install \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# Install core packages (NO input method — added per-variant)
RUN rpm-ostree install \
    # === Spell Check ===
    hunspell-vi \
    # === Fonts ===
    google-noto-sans-fonts \
    # === Symbol/Dingbat font replacements (for WPS Office) ===
    dejavu-sans-fonts \
    dejavu-serif-fonts \
    dejavu-sans-mono-fonts \
    libreoffice-opensymbol-fonts \
    # === Vietnamese Locale ===
    glibc-langpack-vi \
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
    # === Multimedia & Printing (replaces @multimedia @printing) ===
    gstreamer1-plugins-good \
    gstreamer1-plugins-bad-free \
    gstreamer1-plugins-ugly-free \
    gstreamer1-plugin-libav

# Install Plymouth script plugin (required by bamos.script theme)
RUN rpm-ostree install plymouth-plugin-script || echo "plugin already installed"

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

# Copy sudoers for passwordless package management
COPY system_files/shared/etc/sudoers.d/ /etc/sudoers.d/
RUN chown root:root /etc/sudoers.d/bamos-software && \
    chmod 0440 /etc/sudoers.d/bamos-software

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

# Install BamOS Portal (GTK4 first-boot setup wizard)
RUN /usr/libexec/bamos/install-portal.sh || echo "BamOS Portal setup deferred"

# Install BamOS Store (GNOME app store)
RUN /usr/libexec/bamos/install-store.sh || echo "BamOS Store setup deferred"

# Apply branding (logo, Plymouth, OS release)
RUN /usr/libexec/bamos/branding.sh || echo "Branding setup deferred"

# Setup WPS Office config + first-boot installer
RUN /usr/libexec/bamos/install-wps.sh || echo "WPS Office setup deferred"

# Setup Zalo first-boot installer
RUN /usr/libexec/bamos/setup-zalo.sh || echo "Zalo setup deferred to first boot"

# Setup USB Token libraries
RUN /usr/libexec/bamos/setup-token.sh

# =============================================================================
# 6. ADDITIONAL KERNEL MODULES
# =============================================================================

# Install community kernel modules: xone (Xbox), xpadneo (Xbox BT), broadcom-wl, v4l2loopback
RUN /usr/libexec/bamos/install-kmods.sh || echo "Some kmods deferred"

# =============================================================================
# 7. IMAGE INFO
# =============================================================================

# Generate OCI metadata and image info JSON
RUN IMAGE_NAME="${IMAGE_NAME}" IMAGE_VENDOR="${IMAGE_VENDOR}" \
    IMAGE_VERSION="${IMAGE_VERSION}" BASE_IMAGE="${BASE_IMAGE}" \
    /usr/libexec/bamos/image-info.sh

# =============================================================================
# 8. CLEANUP & FINALIZE
# =============================================================================

# Create first-boot service for BamOS Store installation (fallback if build-time fails)
RUN mkdir -p /etc/systemd/system && \
    if ! flatpak list --system 2>/dev/null | grep -q io.github.bazaar_org.bazaar; then \
        printf '[Unit]\nDescription=BamOS Store first-boot installation\nAfter=network-online.target\nWants=network-online.target\nConditionPathExists=!/var/lib/bamos/store-installed\n\n[Service]\nType=oneshot\nExecStart=/usr/libexec/bamos/install-store.sh\nExecStartPost=touch /var/lib/bamos/store-installed\nRemainAfterExit=yes\n\n[Install]\nWantedBy=multi-user.target\n' > /etc/systemd/system/bamos-install-store.service && \
        systemctl enable bamos-install-store.service || true; \
    fi

# Run Bazzite-style finalize: migrate passwd/group, clean locks, temp files, cache
RUN /usr/libexec/bamos/finalize.sh

# Update font cache after all fonts installed
RUN fc-cache -fv

# =============================================================================
# 9. FINAL SYSTEM SETUP
# =============================================================================

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

# Copy Flatpak fixes (per-app post-install hooks: Firefox, StreamController)
COPY system_files/shared/usr/libexec/bamos/internal/flatpak-fixes/ /usr/libexec/bamos/internal/flatpak-fixes/

# Copy Fish shell aliases
COPY system_files/shared/etc/fish/conf.d/ /etc/fish/conf.d/

# Copy Secure Boot certificate
COPY branding/bamos-mok.cer /usr/share/bamos/secureboot/bamos-sb.der

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
# Pre-install BamOS Store via Flatpak (so it's baked into the ISO)
# =============================================================================
RUN flatpak remote-add --if-not-exists --system flathub https://dl.flathub.org/repo/flathub.flatpakrepo && \
    flatpak install -y --noninteractive --system flathub io.github.bazaar_org.bazaar || \
    echo "BamOS Store deferred — will install at first boot"

# =============================================================================
# Enable system services (RakuOS-inspired maintenance timers)
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

# Set default Plymouth theme (no initramfs rebuild — happens at first boot)
RUN plymouth-set-default-theme bamos || true

# =============================================================================
# Stage 2: GNOME Variant (adds ibus-unikey ONLY)
# =============================================================================
FROM bamos-base AS bamos-gnome

ARG IMAGE_NAME="${IMAGE_NAME:-bamos-gnome}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR:-quocnho}"
ARG VERSION_TAG="${VERSION_TAG}"

LABEL org.opencontainers.image.title="BamOS GNOME"
LABEL org.opencontainers.image.description="BamOS GNOME — ibus-unikey Vietnamese input"
LABEL io.bamos.variant="${IMAGE_NAME}"

# Install GNOME input method (ibus-unikey only — no fcitx5)
RUN rpm-ostree install ibus-unikey

# Copy GNOME GSsettings override (RakuOS-inspired theme, extensions, keybindings)
# Only applied on GNOME variants — keeps base stage clean
COPY system_files/shared/usr/share/glib-2.0/schemas/zz-bamos-gnome.gschema.override /usr/share/glib-2.0/schemas/
RUN glib-compile-schemas /usr/share/glib-2.0/schemas/

# =============================================================================
# Stage 3: KDE Variant (adds fcitx5-unikey + KDE config)
# =============================================================================
FROM bamos-base AS bamos-kde

ARG IMAGE_NAME="${IMAGE_NAME:-bamos-kde}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR:-quocnho}"
ARG VERSION_TAG="${VERSION_TAG}"

LABEL org.opencontainers.image.title="BamOS KDE"
LABEL org.opencontainers.image.description="BamOS KDE — fcitx5-unikey Vietnamese input"
LABEL io.bamos.variant="${IMAGE_NAME}"

# Install KDE input method (fcitx5-unikey only — no ibus-unikey)
RUN rpm-ostree install \
    fcitx5 \
    fcitx5-unikey \
    fcitx5-autostart \
    fcitx5-configtool \
    fcitx5-gtk \
    fcitx5-qt

# Copy KDE configuration files (Plasma Win11 layout)
COPY system_files/kde/ /etc/skel/.config/

# Copy Fcitx5 input method configuration
COPY system_files/kde/etc/fcitx5/ /usr/share/bamos/fcitx5/

# =============================================================================
# Stage 4: GNOME-NVIDIA Variant (bamos-gnome + NVIDIA drivers)
# =============================================================================
FROM bamos-gnome AS bamos-nvidia-gnome

ARG IMAGE_NAME="${IMAGE_NAME:-bamos-nvidia-gnome}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR:-quocnho}"
ARG VERSION_TAG="${VERSION_TAG}"
ARG VERSION_PRETTY="${VERSION_PRETTY}"
ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-silverblue}"

LABEL org.opencontainers.image.title="BamOS GNOME NVIDIA"
LABEL org.opencontainers.image.description="BamOS GNOME + NVIDIA (RPM Fusion)"
LABEL io.bamos.nvidia.flavor="rpmfusion"

# Copy NVIDIA system files (firstboot auto-detect, udev rules)
COPY system_files/nvidia/shared/ /

# Remove nouveau driver
RUN rpm-ostree override remove xorg-x11-drv-nouveau || true

# Install NVIDIA open driver + userspace
RUN rpm-ostree install \
    kmod-nvidia-open \
    xorg-x11-drv-nvidia-open-cuda \
    egl-wayland \
    egl-wayland2 \
    nvidia-settings \
    nvidia-persistenced \
    nvidia-vaapi-driver \
    || echo "Some NVIDIA packages deferred"

# NVIDIA Container Toolkit
RUN curl -sL https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo \
    -o /etc/yum.repos.d/nvidia-container-toolkit.repo && \
    rpm-ostree install nvidia-container-toolkit || echo "nvidia-container-toolkit deferred"

# First-boot auto-detection
RUN chmod +x /usr/libexec/bamos/nvidia-setup.sh && \
    chmod +x /usr/libexec/bamos/nvidia-firstboot-setup.sh

RUN printf '[Unit]\nDescription=BamOS NVIDIA First-Boot GPU Detection\nAfter=network.target\nBefore=display-manager.service\n\n[Service]\nType=oneshot\nExecStart=/usr/libexec/bamos/nvidia-firstboot-setup.sh\nRemainAfterExit=yes\nTimeoutStartSec=120\n\n[Install]\nWantedBy=multi-user.target\n' > /etc/systemd/system/bamos-nvidia-firstboot.service && \
    systemctl enable bamos-nvidia-firstboot.service

# Finalize
RUN rpm-ostree cleanup -m && ostree container commit
RUN --mount=type=tmpfs,target=/run --network=none bootc container lint || true

# =============================================================================
# Stage 5: KDE-NVIDIA Variant (bamos-kde + NVIDIA drivers)
# =============================================================================
FROM bamos-kde AS bamos-nvidia-kde

ARG IMAGE_NAME="${IMAGE_NAME:-bamos-nvidia-kde}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR:-quocnho}"
ARG VERSION_TAG="${VERSION_TAG}"
ARG VERSION_PRETTY="${VERSION_PRETTY}"
ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-kinoite}"

LABEL org.opencontainers.image.title="BamOS KDE NVIDIA"
LABEL org.opencontainers.image.description="BamOS KDE + NVIDIA (RPM Fusion)"
LABEL io.bamos.nvidia.flavor="rpmfusion"

# Copy NVIDIA system files
COPY system_files/nvidia/shared/ /

# Remove nouveau driver
RUN rpm-ostree override remove xorg-x11-drv-nouveau || true

# Install NVIDIA open driver + userspace
RUN rpm-ostree install \
    kmod-nvidia-open \
    xorg-x11-drv-nvidia-open-cuda \
    egl-wayland \
    egl-wayland2 \
    nvidia-settings \
    nvidia-persistenced \
    nvidia-vaapi-driver \
    || echo "Some NVIDIA packages deferred"

# NVIDIA Container Toolkit
RUN curl -sL https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo \
    -o /etc/yum.repos.d/nvidia-container-toolkit.repo && \
    rpm-ostree install nvidia-container-toolkit || echo "nvidia-container-toolkit deferred"

# First-boot auto-detection
RUN chmod +x /usr/libexec/bamos/nvidia-setup.sh && \
    chmod +x /usr/libexec/bamos/nvidia-firstboot-setup.sh

RUN printf '[Unit]\nDescription=BamOS NVIDIA First-Boot GPU Detection\nAfter=network.target\nBefore=display-manager.service\n\n[Service]\nType=oneshot\nExecStart=/usr/libexec/bamos/nvidia-firstboot-setup.sh\nRemainAfterExit=yes\nTimeoutStartSec=120\n\n[Install]\nWantedBy=multi-user.target\n' > /etc/systemd/system/bamos-nvidia-firstboot.service && \
    systemctl enable bamos-nvidia-firstboot.service

# Finalize
RUN rpm-ostree cleanup -m && ostree container commit
RUN --mount=type=tmpfs,target=/run --network=none bootc container lint || true
