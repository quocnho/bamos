#!/usr/bin/env bash
# setup-fonts-vn-proprietary — Install Vietnamese proprietary fonts
# Copies VNI, VnTime fonts from existing Windows partition or user-provided source
#
# Usage:
#   bamos setup-fonts-proprietary                    # Auto-detect Windows partition
#   bamos setup-fonts-proprietary /path/to/fonts     # From specific directory
#   bamos setup-fonts-proprietary --help             # Show help

set -euo pipefail

FONT_TARGET="/usr/local/share/fonts/vietnamese"
FONT_USER_TARGET="$HOME/.local/share/fonts/vietnamese"

echo "============================================="
echo "  BamOS Vietnamese Proprietary Fonts Setup"
echo "============================================="
echo ""

show_help() {
    cat << 'EOF'
Cài đặt fonts tiếng Việt bản quyền cho BamOS

Fonts được hỗ trợ:
  VNI:    VNI-Times, VNI-Helve, VNI-Aptima, VNI-Courier
  VnTime: .VnTime, .VnArial, .VnTimeH
  MS:     Times New Roman, Arial, Tahoma, Verdana

Cách sử dụng:
  bamos setup-fonts-proprietary              # Tự động tìm từ Windows (dual-boot)
  bamos setup-fonts-proprietary /path/dir    # Từ thư mục cụ thể
  bamos setup-fonts-proprietary --user-only  # Chỉ cài cho user hiện tại

Nguồn fonts:
  - Phân vùng Windows (C:\Windows\Fonts) nếu dual-boot
  - Bộ cài Office có bản quyền
  - Mua từ nhà cung cấp font (VNI, BKAV, FPT)
EOF
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    show_help
    exit 0
fi

SOURCE_DIR="${1:-}"

# Auto-detect Windows partition
if [ -z "$SOURCE_DIR" ]; then
    echo "Searching for Windows partitions..."
    WINDOWS_PART=$(lsblk -o MOUNTPOINT,FSTYPE -ln | grep -E 'ntfs|vfat' | awk '{print $1}' | head -1 || true)
    if [ -n "$WINDOWS_PART" ]; then
        WINDOWS_FONTS="$WINDOWS_PART/Windows/Fonts"
        if [ -d "$WINDOWS_FONTS" ]; then
            echo "Found Windows fonts at: $WINDOWS_FONTS"
            SOURCE_DIR="$WINDOWS_FONTS"
        fi
    fi
fi

if [ -z "$SOURCE_DIR" ] || [ ! -d "$SOURCE_DIR" ]; then
    echo "Không tìm thấy thư mục fonts."
    echo ""
    echo "Vui lòng cung cấp thư mục chứa font files (.ttf, .otf):"
    echo "  bamos setup-fonts-proprietary /đường/dẫn/thư/mục"
    echo ""
    echo "Bạn có thể lấy fonts từ:"
    echo "  1. Phân vùng Windows (nếu dual-boot)"
    echo "  2. Bộ cài Office Microsoft có bản quyền"
    echo "  3. Mua từ nhà cung cấp: VNI, BKAV-CA, FPT-CA"
    exit 1
fi

echo "Source: $SOURCE_DIR"
echo ""

# Create target directory
mkdir -p "$FONT_USER_TARGET"

# Font mapping: source pattern → installed name
declare -A FONT_MAP=(
    # VNI fonts
    ["VNI-Times"]="vni-times*.ttf VNI-TIMES*.TTF"
    ["VNI-Helve"]="vni-helve*.ttf VNI-HELVE*.TTF"
    ["VNI-Aptima"]="vni-aptima*.ttf VNI-APTIMA*.TTF"
    ["VNI-Courier"]="vni-cour*.ttf VNI-COUR*.TTF"
    # VnTime fonts
    [".VnTime"]=".VnTime*.ttf .vntime*.ttf"
    [".VnArial"]=".VnArial*.ttf .vnarial*.ttf"
    [".VnTimeH"]=".VnTimeH*.ttf .vntimeh*.ttf"
    # Microsoft Core Fonts
    ["Times New Roman"]="times*.ttf Times*.ttf"
    ["Arial"]="arial*.ttf Arial*.ttf"
    ["Tahoma"]="tahoma*.ttf Tahoma*.ttf"
    ["Verdana"]="verdana*.ttf Verdana*.ttf"
    ["Courier New"]="cour*.ttf Cour*.ttf"
    ["Calibri"]="calibri*.ttf Calibri*.ttf"
    ["Cambria"]="cambria*.ttf Cambria*.ttf"
)

INSTALLED_COUNT=0
for FONT_NAME in "${!FONT_MAP[@]}"; do
    PATTERNS="${FONT_MAP[$FONT_NAME]}"
    for pattern in $PATTERNS; do
        FOUND=$(find "$SOURCE_DIR" -iname "$pattern" -type f 2>/dev/null | head -1 || true)
        if [ -n "$FOUND" ]; then
            cp "$FOUND" "$FONT_USER_TARGET/"
            echo "  ✓ $FONT_NAME ← $(basename "$FOUND")"
            INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
            break
        fi
    done
done

if [ $INSTALLED_COUNT -eq 0 ]; then
    echo ""
    echo "Không tìm thấy font nào trong thư mục đã chọn."
    echo "Kiểm tra lại đường dẫn hoặc thử thư mục khác."
    exit 1
fi

# Update font cache
echo ""
echo "Updating font cache..."
fc-cache -fv

echo ""
echo "============================================="
echo "  Đã cài đặt $INSTALLED_COUNT fonts!"
echo "============================================="
echo ""
echo "Fonts đã được cài vào: $FONT_USER_TARGET"
echo "Khởi động lại ứng dụng để sử dụng fonts mới."

if [ $INSTALLED_COUNT -lt 8 ]; then
    echo ""
    echo "Một số fonts chưa được tìm thấy. Để cài fonts Microsoft:"
    echo "  bamos setup-fonts-ms"
fi
