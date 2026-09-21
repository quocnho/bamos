#!/usr/bin/env bash
set -euo pipefail

FLAKE_DIR="/etc/nixos"
STATE_DIR="/var/lib/bamos"
STATE_FILE="$STATE_DIR/last-update-status"
LOG_FILE="/var/log/bamos-update.log"

mkdir -p "$STATE_DIR"
touch "$LOG_FILE" 2>/dev/null || true
exec > >(tee -a "$LOG_FILE") 2>&1

# Host trong flake: máy đích luôn là "bamos"; máy dev (nếu bật) là "lg"
HOST="bamos"
[ "$(cat /proc/sys/kernel/hostname 2>/dev/null || echo x)" = "lg" ] && HOST="lg"

_notify() {
  local title="$1" message="$2" urgency="${3:-normal}"
  local path uid user
  for path in /run/user/*; do
    [ -d "$path" ] || continue
    uid=$(basename "$path")
    user=$(id -nu "$uid" 2>/dev/null) || continue
    runuser -u "$user" -- env \
      XDG_RUNTIME_DIR="/run/user/$uid" \
      DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" \
      notify-send -u "$urgency" -a "Bamos" \
        "$title" "$message" 2>/dev/null || true
  done
}

_fail() {
  local reason="${1:-unknown}"
  echo "failed|$(date -Is)|$reason" > "$STATE_FILE"
  _notify "Cập nhật BamOS — THẤT BẠI" \
    "Tự động cập nhật gặp lỗi ($reason). Xem: sudo cat $LOG_FILE" "critical" || true
  exit 1
}
trap '_fail "script-line-$LINENO"' ERR

_check_disk() {
  local avail_kb avail_gb
  avail_kb=$(df -k /nix/store | awk 'NR==2 {print $4}')
  avail_gb=$((avail_kb / 1024 / 1024))
  if [ "$avail_gb" -lt 5 ]; then
    echo "[ERROR] Không đủ dung lượng /nix/store: ${avail_gb}GB (<5GB)"
    return 1
  fi
  echo "[INFO] Dung lượng /nix/store: ${avail_gb}GB (đủ)"
  return 0
}

echo ""
echo "[$(date -Is)] ==== BamOS auto-update bắt đầu ===="

# 1) Mạng — chờ tối đa 2 phút; không có mạng thì bỏ qua (timer sẽ chạy lại)
if ! timeout 120 nm-online -q 2>/dev/null; then
  echo "[WARN] Chưa có mạng — thử lại ở lần chạy kế tiếp."
  exit 0
fi
echo "[INFO] Mạng OK."

# 2) Flatpak (nếu hệ thống có)
if command -v flatpak >/dev/null 2>&1; then
  echo "[INFO] Cập nhật Flatpak..."
  flatpak update -y || echo "[WARN] flatpak update thất bại (bỏ qua)."
fi

# 3) flake update (tải config mới nhất từ GitHub) — retry 3 lần
LOCK="$FLAKE_DIR/flake.lock"
BEFORE=$(sha256sum "$LOCK" 2>/dev/null | awk '{print $1}' || true)
OWNER=$(stat -c %U:%G "$LOCK" 2>/dev/null || true)
UPDATED=0
for i in 1 2 3; do
  if nix flake update --flake "$FLAKE_DIR"; then
    UPDATED=1
    break
  fi
  echo "[WARN] nix flake update lỗi (lần $i/3) — thử lại..."
  [ "$i" -lt 3 ] && sleep 10
done
[ "$UPDATED" -eq 1 ] || _fail "flake-update"

if [ -n "$OWNER" ]; then
  chown "$OWNER" "$LOCK" 2>/dev/null || true
fi
AFTER=$(sha256sum "$LOCK" | awk '{print $1}')

if [ "$BEFORE" = "$AFTER" ]; then
  echo "[INFO] Không có cập nhật mới."
  if [ -f "$STATE_FILE" ] && grep -q '^failed' "$STATE_FILE"; then
    echo "[INFO] Lần trước ghi nhận lỗi — rebuild thử lại để xác nhận..."
    if BAMOS_TAG="BamOS-$(date +%y.%m.%d-%H:%M)" nixos-rebuild boot --flake "$FLAKE_DIR#$HOST" --impure; then
      echo ok > "$STATE_FILE"
      _notify "Bamos" "Hệ thống đang chạy cấu hình mới nhất."
    else
      _fail "rebuild-retry"
    fi
  else
    echo ok > "$STATE_FILE"
  fi
  exit 0
fi

echo "[INFO] Có bản cập nhật mới — bắt đầu rebuild..."
_check_disk || _fail "disk-space"

# 4) Rebuild boot
BAMOS_TAG="BamOS-$(date +%y.%m.%d-%H:%M)" \
  nixos-rebuild boot --flake "$FLAKE_DIR#$HOST" --impure || _fail "rebuild"

# 5) Dọn rác
nix-collect-garbage --delete-older-than 7d || \
  echo "[WARN] nix-collect-garbage lỗi (bỏ qua)."

# 6) Thông báo thành công
GENERATION=$(readlink /nix/var/nix/profiles/system 2>/dev/null | grep -o 'system-[0-9]*' || echo '?')
echo ok > "$STATE_FILE"
_notify "Cập nhật BamOS thành công" \
  "Hệ thống đã cập nhật lên generation $GENERATION. Nên khởi động lại để áp dụng."
echo "[$(date -Is)] ==== Xong (generation $GENERATION) ===="
