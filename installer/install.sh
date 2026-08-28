#!/usr/bin/env bash
# ============================================================================
# Bamos Installer — cài NixOS (bamos) lên máy người dùng từ LiveCD.
#
# Tham khảo luồng cài của GLF-OS (module Calamares "nixos", xem
# framagit.org/gaming-linux-fr/glf-os — patches/calamares-nixos-extensions):
#   partition → mount → nixos-generate-config → ghi flake + configuration.nix
#   → nixos-install --flake <root>/etc/nixos#bamos
#
# Sau khi cài xong, /etc/nixos của máy đích chứa flake gọi cấu hình từ
# github.com/quocnho/bamos (input `bamos` trong installer/flake.nix).
# ============================================================================

set -euo pipefail

SOURCE_DIR="/installer"   # được nhúng vào ISO qua isoImage.contents
TARGET_ROOT="/mnt"
HOSTNAME="bamos"

msg()  { echo -e "\n\e[1;32m==>\e[0m $*"; }
warn() { echo -e "\n\e[1;33m!\e[0m $*"; }
die()  { echo -e "\n\e[1;31mLỖI:\e[0m $*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# 1. Kiểm tra điều kiện
# ---------------------------------------------------------------------------
[ "$(id -u)" = 0 ] || die "Chạy với quyền root (LiveCD đã autologin root)."
[ -d "$SOURCE_DIR" ] || SOURCE_DIR="/iso/installer" # fallback layout cũ
command -v dialog >/dev/null || die "Thiếu dialog."
command -v parted >/dev/null || die "Thiếu parted."

# nixos-install --flake cần tải github:quocnho/bamos + nixpkgs → cần mạng.
if ! timeout 8 bash -c 'cat < /dev/null > /dev/tcp/github.com/443' 2>/dev/null; then
  warn "Không kết nối được github.com — nixos-install --flake sẽ cần mạng."
  dialog --yesno "Không thấy kết nối internet tới github.com.\n\nCài tiếp (sẽ lỗi nếu mạng không lên)?" 8 60 || exit 1
fi

# ---------------------------------------------------------------------------
# 2. Chọn ổ đĩa (CẢNH BÁO: xóa toàn bộ dữ liệu)
# ---------------------------------------------------------------------------
declare -a MENU
while read -r name size model; do
  MENU+=("$name" "$size $model")
done < <(lsblk -d -o NAME,SIZE,MODEL -n -e 7,11)

[ ${#MENU[@]} -gt 0 ] || die "Không thấy ổ đĩa nào."

DISK=$(dialog --stdout --menu \
  "Chọn ổ đĩa để cài bamos:\n(TOÀN BỘ dữ liệu trên ổ này sẽ bị XÓA!)" \
  15 70 6 "${MENU[@]}") || exit 1
DISK="/dev/$DISK"

dialog --yesno "Cài bamos lên ổ:\n  $DISK\n\nTOÀN BỘ dữ liệu sẽ bị XÓA!\nTiếp tục?" 9 70 || exit 1

# ---------------------------------------------------------------------------
# 3. Phân vùng GPT: ESP 512M (FAT32) + root ext4 (phần còn lại)
# ---------------------------------------------------------------------------
msg "Phân vùng $DISK (GPT: ESP 512M + root ext4)..."
parted -s "$DISK" mklabel gpt \
  mkpart ESP fat32 1MiB 513MiB \
  set 1 esp on \
  mkpart root ext4 513MiB 100% || die "parted thất bại."

# Tên partition khác nhau giữa nvme/mmcblk/vd và sd
case "$DISK" in
  *nvme*|*mmcblk*|*vd*) P1="${DISK}p1"; P2="${DISK}p2" ;;
  *)                   P1="${DISK}1"; P2="${DISK}2" ;;
esac

msg "Định dạng $P1 (FAT32/ESP) và $P2 (ext4)..."
mkfs.fat -F32 "$P1"
mkfs.ext4 -F "$P2"

# ---------------------------------------------------------------------------
# 4. Mount
# ---------------------------------------------------------------------------
msg "Mount $P2 → $TARGET_ROOT, $P1 → $TARGET_ROOT/boot ..."
mount "$P2" "$TARGET_ROOT"
mkdir -p "$TARGET_ROOT/boot"
mount "$P1" "$TARGET_ROOT/boot"

# ---------------------------------------------------------------------------
# 5. Thông tin người dùng
# ---------------------------------------------------------------------------
USERNAME=$(dialog --stdout --inputbox "Tên đăng nhập (user):" 8 60 "user") || exit 1
FULLNAME=$(dialog --stdout --inputbox "Tên đầy đủ (hiển thị trên máy):" 8 60 "$USERNAME") || exit 1
PASSWORD=$(dialog --stdout --passwordbox "Mật khẩu (đổi ngay lần đăng nhập đầu):" 8 60 "") || exit 1
[ -n "$USERNAME" ] || die "Chưa nhập tên đăng nhập."
[ -n "$PASSWORD" ] || die "Chưa nhập mật khẩu."

# ---------------------------------------------------------------------------
# 6. Sinh cấu hình: hardware-configuration.nix (tự dò) + flake + configuration.nix
# ---------------------------------------------------------------------------
msg "nixos-generate-config --root $TARGET_ROOT ..."
nixos-generate-config --root "$TARGET_ROOT"

NIXOS_DIR="$TARGET_ROOT/etc/nixos"
mkdir -p "$NIXOS_DIR"

# flake mẫu: input `bamos` = github:quocnho/bamos → kéo toàn bộ cấu hình
cp "$SOURCE_DIR/flake.nix" "$NIXOS_DIR/flake.nix"

cat > "$NIXOS_DIR/configuration.nix" <<EOF
# Bamos — cấu hình cơ bản do installer sinh (bamos-install).
#
# Toàn bộ module/profile lấy từ github.com/quocnho/bamos qua input "bamos"
# trong flake.nix (mục profiles.*). Muốn bật thêm tính năng:
#   sudo nix flake update --flake /etc/nixos
#   sudo nixos-rebuild switch --flake /etc/nixos#bamos
{ config, lib, pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "$HOSTNAME";

  users.users.$USERNAME = {
    isNormalUser = true;
    description = "$FULLNAME";
    extraGroups = [ "networkmanager" "wheel" ];
    initialPassword = "$PASSWORD";
    shell = pkgs.zsh;
  };

  system.stateVersion = "25.11";
}
EOF

# ---------------------------------------------------------------------------
# 7. Pre-generate flake.lock + nixos-install
#    (GLF-OS từng gặp NAR hash mismatch nếu không lock trước)
# ---------------------------------------------------------------------------
msg "Tạo flake.lock cho /etc/nixos (cần mạng)..."
if ( cd "$NIXOS_DIR" && nix flake lock ); then
  msg "flake.lock OK."
else
  warn "Không lock được — nixos-install sẽ tự lock (vẫn cần mạng)."
fi

msg "Chạy nixos-install --flake (10–30 phút tùy máy, đừng tắt máy)..."
nixos-install \
  --root "$TARGET_ROOT" \
  --flake "$NIXOS_DIR#bamos" \
  --no-root-passwd \
  --option build-users-group "" \
  --option sandbox false \
  || die "nixos-install thất bại — xem log phía trên."

# ---------------------------------------------------------------------------
# 8. Hoàn tất
# ---------------------------------------------------------------------------
dialog --msgbox "CÀI ĐẶT HOÀN TẤT!

/etc/nixos của máy mới đã chứa flake gọi cấu hình từ
github.com/quocnho/bamos (input \"bamos\").

Cập nhật máy sau này:
  sudo nix flake update --flake /etc/nixos
  sudo nixos-rebuild switch --flake /etc/nixos#bamos" 14 70

if dialog --yesno "Khởi động lại ngay?" 6 40; then
  reboot
fi
