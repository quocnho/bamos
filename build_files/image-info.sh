#!/usr/bin/bash
# bamos-image-info.sh — Generate OCI image metadata (adapted from Bazzite image-info)
# Creates /usr/share/bamos/image-info with complete build metadata
# Used by CI/CD to tag images, generate release notes, and track builds

set -euo pipefail

# Read build-time ARGs (set by GitHub Actions or podman build)
IMAGE_NAME="${IMAGE_NAME:-bamos}"
IMAGE_VENDOR="${IMAGE_VENDOR:-quocnho}"
IMAGE_VERSION="${IMAGE_VERSION:-latest}"
IMAGE_COMMIT="${IMAGE_COMMIT:-unknown}"
IMAGE_BUILD_DATE="${IMAGE_BUILD_DATE:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"
IMAGE_REF="${IMAGE_REF:-unknown}"
BASE_IMAGE="${BASE_IMAGE:-unknown}"
FEDORA_VERSION="${FEDORA_VERSION:-$(rpm -E %fedora)}"

OUTPUT_DIR="/usr/share/bamos"
mkdir -p "$OUTPUT_DIR"

# =============================================================================
# Generate image-info JSON
# =============================================================================

cat > "$OUTPUT_DIR/image-info.json" <<EOF
{
  "bamos": {
    "name": "${IMAGE_NAME}",
    "vendor": "${IMAGE_VENDOR}",
    "version": "${IMAGE_VERSION}",
    "build_date": "${IMAGE_BUILD_DATE}",
    "commit": "${IMAGE_COMMIT}",
    "ref": "${IMAGE_REF}"
  },
  "base": {
    "image": "${BASE_IMAGE}",
    "fedora_version": "${FEDORA_VERSION}"
  },
  "features": {
    "vietnamese_input": true,
    "vietnamese_locale": true,
    "vietnamese_fonts": true,
    "wps_office": true,
    "zalo": true,
    "usb_token": true,
    "printing": true,
    "web_apps": true,
    "cachyos_tuning": true,
    "nvidia_auto_detect": false,
    "gnome_extensions": false,
    "kde_win11_theme": false
  },
  "nvidia": {
    "driver_open": "cached",
    "driver_closed": "cached",
    "auto_detect": "firstboot"
  },
  "oci": {
    "labels": {
      "org.opencontainers.image.title": "BamOS",
      "org.opencontainers.image.description": "Vietnamese Linux Distribution",
      "org.opencontainers.image.vendor": "${IMAGE_VENDOR}",
      "org.opencontainers.image.version": "${IMAGE_VERSION}",
      "org.opencontainers.image.created": "${IMAGE_BUILD_DATE}",
      "io.bamos.commit": "${IMAGE_COMMIT}",
      "io.bamos.variant": "${IMAGE_NAME}",
      "io.bamos.fedora": "${FEDORA_VERSION}"
    }
  }
}
EOF

# =============================================================================
# Generate version file
# =============================================================================

cat > "$OUTPUT_DIR/version" <<EOF
${IMAGE_VERSION}
EOF

# =============================================================================
# Generate os-release supplementary info
# =============================================================================

cat > "$OUTPUT_DIR/os-release-supplement" <<EOF
BAMOS_IMAGE_NAME="${IMAGE_NAME}"
BAMOS_IMAGE_VERSION="${IMAGE_VERSION}"
BAMOS_COMMIT="${IMAGE_COMMIT}"
BAMOS_BUILD_DATE="${IMAGE_BUILD_DATE}"
BAMOS_FEDORA_VERSION="${FEDORA_VERSION}"
BAMOS_BASE_IMAGE="${BASE_IMAGE}"
EOF

echo "[bamos] Image info generated at $OUTPUT_DIR/image-info.json"
echo "[bamos] Version: ${IMAGE_VERSION}"
echo "[bamos] Build: ${IMAGE_BUILD_DATE}"
echo "[bamos] Commit: ${IMAGE_COMMIT}"
