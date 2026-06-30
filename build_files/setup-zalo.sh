#!/bin/bash
# setup-zalo.sh — Pre-configure Zalo for first-boot installation
# Zalo is a Vietnamese messaging app.
# During build: create wine prefix, download installer, create desktop entry.
# During first boot: install Zalo via systemd service + notify user.

set -euo pipefail

echo "Setting up Zalo..."

ZALO_DOWNLOAD_URL="https://res-zalo.zadn.vn/forbidden/zalo/Zalo_PC_win_global_latest.exe"
ZALO_INSTALL_DIR="/opt/zalo"
WINE_PREFIX="${ZALO_INSTALL_DIR}/wineprefix"

# =============================================================================
# 1. Create directories
# =============================================================================
mkdir -p "${ZALO_INSTALL_DIR}" 2>/dev/null || true
mkdir -p "${WINE_PREFIX}" 2>/dev/null || true

# =============================================================================
# 2. Create desktop entry (points to first-boot installer)
# =============================================================================
mkdir -p /usr/share/applications/
cat > /usr/share/applications/zalo.desktop << 'EOF'
[Desktop Entry]
Name=Zalo
Name[vi]=Zalo
Comment=Vietnamese messaging app — Cài đặt lần đầu khi chạy
Comment[vi]=Ứng dụng nhắn tin Zalo — cài đặt lần đầu khi chạy
Exec=/usr/libexec/bamos/bamos-install-zalo.sh
Icon=zalo
Terminal=true
Type=Application
Categories=Network;InstantMessaging;
StartupWMClass=Zalo
EOF

chmod +x /usr/share/applications/zalo.desktop

# =============================================================================
# 3. Create first-boot installer script
# =============================================================================
cat > /usr/libexec/bamos/bamos-install-zalo.sh << 'ZALOEOF'
#!/bin/bash
# bamos-install-zalo.sh — First-boot Zalo installer
# Runs when user clicks the Zalo desktop icon for the first time

ZALO_INSTALL_DIR="/opt/zalo"
WINE_PREFIX="${ZALO_INSTALL_DIR}/wineprefix"

# Check if already installed
if [ -f "${WINE_PREFIX}/drive_c/Program Files/Zalo/Zalo.exe" ]; then
    echo "Zalo đã được cài đặt. Đang khởi chạy..."
    echo "Zalo is already installed. Launching..."
    env WINEPREFIX="${WINE_PREFIX}" wine "${WINE_PREFIX}/drive_c/Program Files/Zalo/Zalo.exe"
    exit 0
fi

echo "Đang cài đặt Zalo..."
echo "Installing Zalo..."
echo ""

# Check if wine is installed
if ! command -v wine &>/dev/null; then
    echo "Cài đặt Wine..."
    echo "Installing Wine..."
    if command -v rpm-ostree &>/dev/null; then
        sudo rpm-ostree install wine wine-core wine-mono
    elif command -v rakuos &>/dev/null; then
        sudo rakuos install wine wine-core wine-mono
    else
        sudo dnf5 install wine wine-core wine-mono
    fi
fi

# Download Zalo
echo "Đang tải Zalo..."
echo "Downloading Zalo..."
TMPFILE=$(mktemp)
curl -L -o "$TMPFILE" "https://res-zalo.zadn.vn/forbidden/zalo/Zalo_PC_win_global_latest.exe" || {
    echo "Không thể tải Zalo. Mở web version..."
    echo "Cannot download Zalo. Opening web version..."
    xdg-open https://chat.zalo.me
    rm -f "$TMPFILE"
    exit 1
}

# Initialize wine prefix
mkdir -p "${WINE_PREFIX}"
export WINEPREFIX="${WINE_PREFIX}"
export WINEARCH="win64"

echo "Đang khởi tạo Wine prefix..."
echo "Initializing Wine prefix..."
wineboot -u 2>/dev/null || true

# Install Zalo
echo "Đang cài đặt Zalo..."
echo "Installing Zalo..."
wine "$TMPFILE" /S 2>/dev/null || {
    echo "Cài đặt Zalo thất bại. Thử cài thủ công hoặc dùng web version."
    echo "Zalo installation failed. Try manual install or use web version."
    rm -f "$TMPFILE"
    exit 1
}

rm -f "$TMPFILE"

echo ""
echo "✅ Zalo đã được cài đặt thành công!"
echo "✅ Zalo installed successfully!"
echo ""
echo "Chạy 'zalo' từ terminal hoặc click icon Zalo để mở."
echo "Run 'zalo' from terminal or click the Zalo icon to open."
ZALOEOF

chmod +x /usr/libexec/bamos/bamos-install-zalo.sh

# =============================================================================
# 4. Also create a web app fallback shortcut
# =============================================================================
mkdir -p /usr/share/applications/
cat > /usr/share/applications/zalo-web.desktop << 'EOF'
[Desktop Entry]
Name=Zalo Web
Name[vi]=Zalo Web
Comment=Zalo via browser
Comment[vi]=Zalo qua trình duyệt
Exec=xdg-open https://chat.zalo.me
Icon=zalo
Terminal=false
Type=Application
Categories=Network;InstantMessaging;
StartupWMClass=Zalo Web
EOF

echo "Zalo setup complete!"
echo "First-boot installer at: /usr/libexec/bamos/bamos-install-zalo.sh"
echo "Web fallback at: /usr/share/applications/zalo-web.desktop"
