#!/bin/bash
# setup-zalo.sh
# Sets up Zalo messaging application for Vietnamese users
# Uses Wine/Proton for best experience

set -e

echo "Setting up Zalo..."

ZALO_DOWNLOAD_URL="https://res-zalo.zadn.vn/forbidden/zalo/Zalo_PC_win_global_latest.exe"
ZALO_INSTALL_DIR="/opt/zalo"
WINE_PREFIX="${ZALO_INSTALL_DIR}/wineprefix"

# Create directories
mkdir -p "${ZALO_INSTALL_DIR}"
mkdir -p "${WINE_PREFIX}"

# Download Zalo installer
echo "Downloading Zalo..."
curl -L -o /tmp/ZaloSetup.exe "${ZALO_DOWNLOAD_URL}" || {
    echo "WARNING: Could not download Zalo. Will create desktop shortcut for web version instead."
    # Fallback: Create web app shortcut
    mkdir -p /usr/share/applications/
    cat > /usr/share/applications/zalo.desktop << 'EOF'
[Desktop Entry]
Name=Zalo
Name[vi]=Zalo
Comment=Vietnamese messaging app
Comment[vi]=Ứng dụng nhắn tin Zalo
Exec=chromium-browser --app=https://chat.zalo.me --class=Zalo
Icon=zalo
Terminal=false
Type=Application
Categories=Network;InstantMessaging;
StartupWMClass=Zalo
EOF
    exit 0
}

# Install Wine dependencies for Zalo
rpm-ostree install \
    wine \
    wine-core \
    wine-mono \
    || echo "Wine installation deferred. Zalo requires Wine to be installed."

# Set WINEPREFIX
export WINEPREFIX="${WINE_PREFIX}"
export WINEARCH="win64"

# Initialize Wine prefix
wineboot -u || true

# Run Zalo installer silently
echo "Installing Zalo..."
wine /tmp/ZaloSetup.exe /S || {
    echo "WARNING: Zalo installation via Wine failed."
    echo "Please install Zalo manually after system setup."
    echo "Web version available at: https://chat.zalo.me"
}

# Create desktop entry for Zalo
mkdir -p /usr/share/applications/
cat > /usr/share/applications/zalo.desktop << 'EOF'
[Desktop Entry]
Name=Zalo
Name[vi]=Zalo
Comment=Vietnamese messaging app
Comment[vi]=Ứng dụng nhắn tin Zalo
Exec=env WINEPREFIX=/opt/zalo/wineprefix wine /opt/zalo/wineprefix/drive_c/Program Files/Zalo/Zalo.exe
Icon=zalo
Terminal=false
Type=Application
Categories=Network;InstantMessaging;
StartupWMClass=Zalo.exe
EOF

# Clean up
rm -f /tmp/ZaloSetup.exe

echo "Zalo setup complete!"
