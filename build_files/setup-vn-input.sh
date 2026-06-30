#!/bin/bash
# setup-vn-input.sh — Vietnamese Input Method Setup
# Detects desktop environment and configures the appropriate input method:
#   - GNOME:     ibus-unikey via GSsettings
#   - KDE:       fcitx5-unikey via fcitx5 + Plasma config
#
# Both use Super+Space to toggle EN/VI.

set -e

# =============================================================================
# GNOME: Configure ibus-unikey
# =============================================================================
setup_ibus() {
    # Ensure ibus-unikey is installed
    if ! rpm -q ibus-unikey &>/dev/null; then
        echo "[bamos] Installing ibus-unikey..."
        rpm-ostree install ibus-unikey 2>/dev/null || true
    fi

    # Activate ibus daemon for GNOME
    gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('ibus', 'unikey')]" 2>/dev/null || true

    # Ensure ibus starts at login
    mkdir -p /etc/xdg/autostart
    cat > /etc/xdg/autostart/ibus-unikey.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=ibus-unikey
Exec=ibus-daemon -drx
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF

    echo "[bamos] ibus-unikey configured. Super+Space to toggle EN/VI."
}

# =============================================================================
# KDE: Configure fcitx5-unikey
# =============================================================================
setup_fcitx5() {
    # Ensure fcitx5 packages are installed
    for pkg in fcitx5 fcitx5-unikey fcitx5-configtool fcitx5-gtk fcitx5-qt fcitx5-autostart; do
        if ! rpm -q "$pkg" &>/dev/null; then
            echo "[bamos] Installing $pkg..."
            rpm-ostree install "$pkg" 2>/dev/null || true
        fi
    done

    # Copy system-wide fcitx5 config
    if [[ -d /usr/share/bamos/fcitx5/ ]]; then
        mkdir -p /etc/fcitx5/conf
        cp -r /usr/share/bamos/fcitx5/profile /etc/fcitx5/ 2>/dev/null || true
        cp -r /usr/share/bamos/fcitx5/config /etc/fcitx5/ 2>/dev/null || true
        cp -r /usr/share/bamos/fcitx5/conf/*.conf /etc/fcitx5/conf/ 2>/dev/null || true
    fi

    # Set KDE input method to fcitx5
    if command -v kwriteconfig5 &>/dev/null; then
        kwriteconfig5 --file kcminputrc --group "Keyboard" --key "InputMethod" "fcitx5" 2>/dev/null || true
    fi

    # Ensure fcitx5 autostarts
    mkdir -p /etc/xdg/autostart
    cat > /etc/xdg/autostart/fcitx5-bamos.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=fcitx5
Exec=fcitx5 -d
NoDisplay=true
X-KDE-autostart-enabled=true
EOF

    echo "[bamos] fcitx5-unikey configured. Super+Space to toggle EN/VI."
}

# =============================================================================
# Main: Detect DE and configure
# =============================================================================
echo "[bamos] Setting up Vietnamese input method..."

# Detect desktop environment
CURRENT_DE="${XDG_CURRENT_DESKTOP,,}"
if [[ "$CURRENT_DE" == *"kde"* ]]; then
    echo "[bamos] KDE Plasma detected — configuring fcitx5-unikey..."
    setup_fcitx5
else
    echo "[bamos] GNOME detected — configuring ibus-unikey..."
    setup_ibus
fi

echo "[bamos] Vietnamese input setup complete!"
