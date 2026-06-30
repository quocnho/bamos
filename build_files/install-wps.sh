#!/bin/bash
# install-wps.sh — Pre-configure WPS Office for first-boot installation
# WPS Office is proprietary software. Users accept EULA during first launch.
# Download URL changes frequently — better to install at runtime.

set -euo pipefail

echo "Setting up WPS Office..."

# =============================================================================
# 1. Create WPS Office configuration directory
# =============================================================================
mkdir -p /etc/skel/.config/Kingsoft/Office6/

# Configure WPS Office for Vietnamese
cat > /etc/skel/.config/Kingsoft/Office6/wps_oem.ini << 'EOF'
[Support]
SupportVba=1

[Setup]
IsCreateNewFile=0
FirstLaunch=0

[UI]
Language=vi_VN
EOF

# =============================================================================
# 2. Create first-boot installer script
# =============================================================================
cat > /usr/libexec/bamos/bamos-install-wps.sh << 'WPSEOF'
#!/bin/bash
# bamos-install-wps.sh — First-boot WPS Office installer
# Runs when user clicks the WPS Office desktop icon for the first time

set -euo pipefail

# Check if WPS is already installed
if command -v wps &>/dev/null; then
    echo "WPS Office đã được cài đặt. Đang khởi chạy..."
    echo "WPS Office is already installed. Launching..."
    exec wps
fi

echo "Đang cài đặt WPS Office..."
echo "Installing WPS Office..."
echo ""

# Try common download URLs (WPS changes URLs frequently)
WPS_VERSION="11.1.0.11720"
WPS_URLS=(
    "https://wps.com/office/linux/wps-office-${WPS_VERSION}.XA-1.x86_64.rpm"
    "https://wdl1.pcfg.cache.wpscdn.com/wpsdl/wpsoffice/download/linux/${WPS_VERSION}/wps-office-${WPS_VERSION}.XA-1.x86_64.rpm"
    "https://archive.wps.com/office/linux/wps-office-${WPS_VERSION}.XA-1.x86_64.rpm"
)

TMPFILE=$(mktemp /tmp/wps-office.XXXXXX.rpm)
trap 'rm -f "$TMPFILE"' EXIT

DOWNLOADED=false
for url in "${WPS_URLS[@]}"; do
    echo "Đang tải từ: $url"
    echo "Downloading from: $url"
    HTTP_CODE=$(curl -L -o "$TMPFILE" -w "%{http_code}" --connect-timeout 10 --max-time 300 "$url" 2>/dev/null || echo "000")
    if [[ "$HTTP_CODE" =~ ^2[0-9][0-9]$ ]] && [[ -s "$TMPFILE" ]]; then
        echo "Tải thành công! (HTTP $HTTP_CODE, $(du -h "$TMPFILE" | cut -f1))"
        DOWNLOADED=true
        break
    fi
    echo "Thất bại (HTTP $HTTP_CODE). Thử URL khác..."
done

if [[ "$DOWNLOADED" != "true" ]]; then
    echo ""
    echo "⚠️  Không thể tải WPS Office tự động."
    echo "   Cannot download WPS Office automatically."
    echo ""
    echo "Vui lòng tải thủ công từ:"
    echo "Please download manually from:"
    echo "  https://www.wps.com/office/linux/"
    echo ""
    echo "Sau đó cài: sudo rpm-ostree install ~/Downloads/wps-office*.rpm"
    echo ""
    read -p "Nhấn Enter để mở trang tải WPS... (Press Enter to open download page)"
    xdg-open "https://www.wps.com/office/linux/" 2>/dev/null || true
    exit 1
fi

# Install via rpm-ostree
echo "Đang cài đặt WPS Office..."
echo "Installing WPS Office..."
if command -v rpm-ostree &>/dev/null; then
    sudo rpm-ostree install "$TMPFILE"
elif command -v rakuos &>/dev/null; then
    sudo rakuos install "$TMPFILE"
else
    sudo dnf5 install "$TMPFILE"
fi

echo ""
echo "✅ WPS Office đã được cài đặt thành công!"
echo "✅ WPS Office installed successfully!"
echo ""
echo "⚠️  KHỞI ĐỘNG LẠI để áp dụng: systemctl reboot"
echo "⚠️  REBOOT REQUIRED: systemctl reboot"
echo ""

read -p "Nhấn Enter để đóng... (Press Enter to close)"
WPSEOF

chmod +x /usr/libexec/bamos/bamos-install-wps.sh

# =============================================================================
# 3. WPS desktop shortcut already handled by system_files/usr/local/bin/wps
# =============================================================================

echo "WPS Office setup complete!"
echo "First-boot installer at: /usr/libexec/bamos/bamos-install-wps.sh"
echo "Run: wps (installs and configures on first launch)"
