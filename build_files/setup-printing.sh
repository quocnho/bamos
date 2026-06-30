#!/bin/bash
# setup-printing.sh — Install printer drivers and start CUPS
# Designed for first-boot use via BamOS Portal or CLI
# Uses rpm-ostree to layer printer packages (requires reboot)

set -euo pipefail

echo "🖨️  Đang cài đặt máy in..."
echo "🖨️  Installing printer support..."

# =============================================================================
# 1. Install printer packages via rpm-ostree
# =============================================================================
echo "1. Cài đặt driver máy in..."
echo "   Installing printer drivers..."

rpm-ostree install \
    cups \
    cups-pdf \
    system-config-printer \
    hplip \
    gutenprint-cups \
    foomatic-db-ppds || {
    echo "⚠️  Một số gói không có sẵn. Vui lòng cài thủ công:"
    echo "   sudo rpm-ostree install cups hplip gutenprint-cups"
    exit 1
}

# =============================================================================
# 2. Enable CUPS service
# =============================================================================
echo "2. Kích hoạt dịch vụ in ấn (CUPS)..."
echo "   Enabling CUPS service..."
systemctl enable cups 2>/dev/null || true

# =============================================================================
# 3. Add user to lpadmin group (for printer management without root)
# =============================================================================

# =============================================================================
# 4. Done
# =============================================================================
echo ""
echo "✅ Printer support staged for installation!"
echo "   ✅ Driver máy in đã được xếp hàng chờ cài đặt."
echo ""
echo "⚠️  KHỞI ĐỘNG LẠI để áp dụng: systemctl reboot"
echo "⚠️  REBOOT REQUIRED to apply: systemctl reboot"
echo ""
echo "   Sau khi khởi động lại:"
echo "   - Mở: http://localhost:631 (CUPS web interface)"
echo "   - Hoặc dùng: system-config-printer"
echo "   - Thêm user vào nhóm lpadmin: sudo usermod -aG lpadmin $USER"
