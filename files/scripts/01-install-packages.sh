#!/usr/bin/env bash
set -ouex pipefail

echo "=== BamOS: DE Package Installation ==="

IMAGE_NAME="${IMAGE_NAME:-bamos}"

IS_KDE=false
IS_GNOME=false
IS_COSMIC=false
[[ "$IMAGE_NAME" == *-kde* ]] && IS_KDE=true
[[ "$IMAGE_NAME" == *-gnome* ]] && IS_GNOME=true
[[ "$IMAGE_NAME" == *-cosmic* ]] && IS_COSMIC=true

# DE-specific post-install steps (actual package removal is in recipe YAML)
if [[ "$IS_GNOME" == "true" ]]; then
    # Compile GSettings schemas (picks up BamOS GNOME overrides)
    glib-compile-schemas /usr/share/glib-2.0/schemas/ 2>/dev/null || true
    echo "GSettings schemas compiled for GNOME."
fi

if [[ "$IS_COSMIC" == "true" ]]; then
    # COSMIC uses its own Flatpak repo for some apps
    flatpak remote-add --if-not-exists cosmic \
        https://apt.pop-os.org/cosmic/cosmic.flatpakrepo 2>/dev/null || true
    echo "COSMIC Flatpak repo added."
fi

echo "=== BamOS: DE Package Installation Complete ==="
