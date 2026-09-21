#!/usr/bin/env bash
STATE_FILE="/var/lib/bamos/last-update-status"
LOG_FILE="/var/log/bamos-update.log"
REASON="unknown"
[ -f "$STATE_FILE" ] && REASON=$(cut -d'|' -f3- "$STATE_FILE" 2>/dev/null || echo unknown)

for path in /run/user/*; do
  [ -d "$path" ] || continue
  uid=$(basename "$path")
  user=$(id -nu "$uid" 2>/dev/null) || continue
  runuser -u "$user" -- env \
    XDG_RUNTIME_DIR="/run/user/$uid" \
    DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" \
    notify-send -u critical -a "Bamos" \
      "Cập nhật BamOS — lỗi hệ thống" \
      "Auto-update gặp lỗi ($REASON). Xem: sudo cat $LOG_FILE" 2>/dev/null || true
done
