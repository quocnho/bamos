#!/usr/bin/bash
# bamos-finalize.sh — Final image cleanup (adapted from Bazzite finalize)
# Ensures OCI image is production-clean:
#   1. Migrates /etc/passwd & /etc/group to /usr/lib/ for stateless OCI
#   2. Removes lock files, temp files, cache
#   3. DNF cache cleanup
#   4. Sets proper permissions

set -eoux pipefail

echo "[bamos] Finalizing image..."

# =============================================================================
# 1. Disable DNF cache retention for smaller image size
# =============================================================================

if command -v dnf5 &>/dev/null; then
    dnf5 config-manager setopt keepcache=0 2>/dev/null || true
fi

# =============================================================================
# 2. Clean temporary files
# =============================================================================

rm -rf /tmp/* || true
rm -rf /var/tmp/* || true
mkdir -p /var/tmp
chmod -R 1777 /var/tmp

# =============================================================================
# 3. Migrate /etc/passwd & /etc/group to /usr/lib (uBlue/Bazzite standard)
#    Makes the image stateless — proper OCI practice
# =============================================================================

if [ -f /etc/passwd ]; then
    out=$(grep -v "root" /etc/passwd) || true
    if [ -n "$out" ]; then
        echo "[bamos] Moving non-root passwd entries to /usr/lib/passwd..."
        echo "$out" >> /usr/lib/passwd
        echo "root:x:0:0:root:/root:/bin/bash" > /etc/passwd
    fi
fi

if [ -f /etc/group ]; then
    out=$(grep -v "root\|wheel" /etc/group) || true
    if [ -n "$out" ]; then
        echo "[bamos] Moving non-system group entries to /usr/lib/group..."
        echo "$out" >> /usr/lib/group
        echo "root:x:0:" > /etc/group
        echo "wheel:x:10:" >> /etc/group
    fi
fi

# =============================================================================
# 4. Remove lock files and backup files
# =============================================================================

rm -rf \
    /etc/.pwd.lock \
    /etc/passwd- \
    /etc/group- \
    /etc/shadow- \
    /etc/gshadow- \
    /etc/subuid- \
    /etc/subgid- \
    2>/dev/null || true

# =============================================================================
# 5. Clean DNF/RPM cache
# =============================================================================

rm -rf /var/cache/dnf/* 2>/dev/null || true
rm -rf /var/cache/libdnf5/* 2>/dev/null || true
rm -rf /var/lib/dnf/* 2>/dev/null || true

# =============================================================================
# 6. Clean RPM database backups
# =============================================================================

rm -f /var/lib/rpm/__db.* 2>/dev/null || true
rpm --rebuilddb 2>/dev/null || true

# =============================================================================
# 7. Remove build artifacts
# =============================================================================

rm -rf \
    /root/.cache \
    /root/.cargo \
    2>/dev/null || true

# =============================================================================
# 8. Update system file databases
# =============================================================================

if command -v update-desktop-database &>/dev/null; then
    update-desktop-database /usr/share/applications 2>/dev/null || true
fi

if command -v gtk-update-icon-cache &>/dev/null; then
    gtk-update-icon-cache -f -t /usr/share/icons/hicolor 2>/dev/null || true
fi

# =============================================================================
# 9. Final rpm-ostree cleanup
# =============================================================================

if command -v rpm-ostree &>/dev/null; then
    rpm-ostree cleanup -m 2>/dev/null || true
fi

echo "[bamos] Image finalized successfully."
