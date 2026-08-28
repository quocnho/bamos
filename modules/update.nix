# TỰ ĐỘNG CẬP NHẬT hệ thống từ GitHub — tham khảo sâu `glfos-update` của GLF-OS
# (modules/default/update.nix của họ):
#
#   - systemd timer (12h, ngẫu nhiên hóa giờ chạy) → script cập nhật
#   - Script: chờ mạng (nm-online) → flatpak update (nếu có) → `nix flake update`
#     (kéo config mới nhất từ github:quocnho/bamos/main + nixpkgs, retry 3 lần)
#     → nếu có thay đổi: check đĩa → `nixos-rebuild boot` (áp dụng khi khởi động
#     lại — KHÔNG làm phiền phiên làm việc đang chạy) → GC giữ 7 ngày → notify-send
#   - State file /var/lib/bamos/last-update-status + log /var/log/bamos-update.log
#   - Lần trước FAIL + không có bản mới → tự rebuild thử lại (tránh báo nhầm "đã
#     cập nhật" khi máy vẫn đang chạy generation cũ hỏng — bài học GLF-OS #191)
#   - onFailure → service thông báo lỗi critical cho mọi user đang đăng nhập
#
# Bật trên máy đích:  my.update.enable = true;  (iso-cfg/customConfig/features.nix)
{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.my.update.enable = lib.mkOption {
    description = "Tự động cập nhật hệ thống từ GitHub (systemd timer + thông báo)";
    type = lib.types.bool;
    default = false;
  };

  config = lib.mkIf config.my.update.enable {
    environment.etc."bamos/update.sh" = {
      mode = "0755";
      text = ''
        #!${pkgs.bash}/bin/bash
        set -euo pipefail

        FLAKE_DIR="/etc/nixos"
        STATE_DIR="/var/lib/bamos"
        STATE_FILE="$STATE_DIR/last-update-status"
        LOG_FILE="/var/log/bamos-update.log"

        mkdir -p "$STATE_DIR"
        touch "$LOG_FILE" 2>/dev/null || true
        exec > >(${pkgs.coreutils}/bin/tee -a "$LOG_FILE") 2>&1

        # Host trong flake: máy đích luôn là "bamos"; máy dev (nếu bật) là "lg"
        HOST="bamos"
        [ "$(cat /proc/sys/kernel/hostname 2>/dev/null || echo x)" = "lg" ] && HOST="lg"

        _notify() {
          local title="$1" message="$2" urgency="''${3:-normal}"
          local path uid user
          for path in /run/user/*; do
            [ -d "$path" ] || continue
            uid=$(basename "$path")
            user=$(${pkgs.shadow}/bin/id -nu "$uid" 2>/dev/null) || continue
            ${pkgs.util-linux}/bin/runuser -u "$user" -- env \
              XDG_RUNTIME_DIR="/run/user/$uid" \
              DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" \
              ${pkgs.libnotify}/bin/notify-send -u "$urgency" -a "Bamos" \
                "$title" "$message" 2>/dev/null || true
          done
        }

        _fail() {
          local reason="''${1:-unknown}"
          echo "failed|$(${pkgs.coreutils}/bin/date -Is)|$reason" > "$STATE_FILE"
          _notify "Cập nhật BamOS — THẤT BẠI" \
            "Tự động cập nhật gặp lỗi ($reason). Xem: sudo cat $LOG_FILE" "critical" || true
          exit 1
        }
        trap '_fail "script-line-$LINENO"' ERR

        _check_disk() {
          local avail_kb avail_gb
          avail_kb=$(${pkgs.coreutils}/bin/df -k /nix/store | ${pkgs.gawk}/bin/awk 'NR==2 {print $4}')
          avail_gb=$((avail_kb / 1024 / 1024))
          if [ "$avail_gb" -lt 5 ]; then
            echo "[ERROR] Không đủ dung lượng /nix/store: ''${avail_gb}GB (<5GB)"
            return 1
          fi
          echo "[INFO] Dung lượng /nix/store: ''${avail_gb}GB (đủ)"
          return 0
        }

        echo ""
        echo "[$(${pkgs.coreutils}/bin/date -Is)] ==== BamOS auto-update bắt đầu ===="

        # 1) Mạng — chờ tối đa 2 phút; không có mạng thì bỏ qua (timer sẽ chạy lại)
        if ! ${pkgs.coreutils}/bin/timeout 120 ${pkgs.networkmanager}/bin/nm-online -q 2>/dev/null; then
          echo "[WARN] Chưa có mạng — thử lại ở lần chạy kế tiếp."
          exit 0
        fi
        echo "[INFO] Mạng OK."

        # 2) Flatpak (nếu hệ thống có)
        if ${pkgs.coreutils}/bin/command -v flatpak >/dev/null 2>&1; then
          echo "[INFO] Cập nhật Flatpak..."
          flatpak update -y || echo "[WARN] flatpak update thất bại (bỏ qua)."
        fi

        # 3) flake update (tải config mới nhất từ GitHub) — retry 3 lần
        LOCK="$FLAKE_DIR/flake.lock"
        BEFORE=$(${pkgs.coreutils}/bin/sha256sum "$LOCK" 2>/dev/null | ${pkgs.gawk}/bin/awk '{print $1}' || true)
        OWNER=$(${pkgs.coreutils}/bin/stat -c %U:%G "$LOCK" 2>/dev/null || true)
        UPDATED=0
        for i in 1 2 3; do
          if ${pkgs.nix}/bin/nix flake update --flake "$FLAKE_DIR"; then
            UPDATED=1
            break
          fi
          echo "[WARN] nix flake update lỗi (lần $i/3) — thử lại..."
          [ "$i" -lt 3 ] && sleep 10
        done
        [ "$UPDATED" -eq 1 ] || _fail "flake-update"
        # Giữ nguyên chủ sở hữu flake.lock (máy dev: không đổi sang root)
        if [ -n "$OWNER" ]; then
          ${pkgs.coreutils}/bin/chown "$OWNER" "$LOCK" 2>/dev/null || true
        fi
        AFTER=$(${pkgs.coreutils}/bin/sha256sum "$LOCK" | ${pkgs.gawk}/bin/awk '{print $1}')

        if [ "$BEFORE" = "$AFTER" ]; then
          echo "[INFO] Không có cập nhật mới."
          # Bài học GLF-OS #191: lần trước fail + không có bản mới → rebuild thử
          # lại để xác nhận, tránh báo nhầm "đã cập nhật" khi vẫn chạy bản cũ hỏng.
          if [ -f "$STATE_FILE" ] && ${pkgs.gnugrep}/bin/grep -q '^failed' "$STATE_FILE"; then
            echo "[INFO] Lần trước ghi nhận lỗi — rebuild thử lại để xác nhận..."
            if BAMOS_TAG="BamOS-$(date +%y.%m.%d-%H:%M)" ${pkgs.nixos-rebuild}/bin/nixos-rebuild boot --flake "$FLAKE_DIR#$HOST" --impure; then
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

        # 4) Rebuild boot — áp dụng khi khởi động lại (an toàn, không gián đoạn),
        #    kèm tag "BamOS-YY.MM.DD-HH:MM" để dễ nhận biết generation.
        BAMOS_TAG="BamOS-$(date +%y.%m.%d-%H:%M)" \
          ${pkgs.nixos-rebuild}/bin/nixos-rebuild boot --flake "$FLAKE_DIR#$HOST" --impure || _fail "rebuild"

        # 5) Dọn rác: giữ 7 ngày (khớp nix.gc.automatic trong modules/nix.nix)
        ${pkgs.nix}/bin/nix-collect-garbage --delete-older-than 7d || \
          echo "[WARN] nix-collect-garbage lỗi (bỏ qua)."

        # 6) Thông báo thành công
        GENERATION=$(${pkgs.coreutils}/bin/readlink /nix/var/nix/profiles/system 2>/dev/null | ${pkgs.gnugrep}/bin/grep -o 'system-[0-9]*' || echo '?')
        echo ok > "$STATE_FILE"
        _notify "Cập nhật BamOS thành công" \
          "Hệ thống đã cập nhật lên generation $GENERATION. Nên khởi động lại để áp dụng."
        echo "[$(${pkgs.coreutils}/bin/date -Is)] ==== Xong (generation $GENERATION) ===="
      '';
    };

    # Thông báo khi service bamos-update chết bất ngờ (onFailure)
    environment.etc."bamos/update-notify-failure.sh" = {
      mode = "0755";
      text = ''
        #!${pkgs.bash}/bin/bash
        STATE_FILE="/var/lib/bamos/last-update-status"
        LOG_FILE="/var/log/bamos-update.log"
        REASON="unknown"
        [ -f "$STATE_FILE" ] && REASON=$(${pkgs.coreutils}/bin/cut -d'|' -f3- "$STATE_FILE" 2>/dev/null || echo unknown)

        for path in /run/user/*; do
          [ -d "$path" ] || continue
          uid=$(basename "$path")
          user=$(${pkgs.shadow}/bin/id -nu "$uid" 2>/dev/null) || continue
          ${pkgs.util-linux}/bin/runuser -u "$user" -- env \
            XDG_RUNTIME_DIR="/run/user/$uid" \
            DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" \
            ${pkgs.libnotify}/bin/notify-send -u critical -a "Bamos" \
              "Cập nhật BamOS — lỗi hệ thống" \
              "Auto-update gặp lỗi ($REASON). Xem: sudo cat $LOG_FILE" 2>/dev/null || true
        done
      '';
    };

    systemd.services."bamos-update" = {
      description = "Bamos auto-update (tự cập nhật hệ thống từ GitHub)";
      wantedBy = [ ];
      path = with pkgs; [
        nix
        nixos-rebuild
        coreutils
        gawk
        gnugrep
        gnused
        util-linux
        networkmanager
        libnotify
        shadow
        flatpak
      ];
      onFailure = [ "bamos-update-notify-failure.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "/etc/bamos/update.sh";
        KillMode = "process";
        StandardOutput = "journal";
        StandardError = "journal";
      };
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
    };

    systemd.services."bamos-update-notify-failure" = {
      description = "Thông báo khi bamos-update thất bại ngoài dự kiến";
      path = with pkgs; [
        libnotify
        shadow
        coreutils
        util-linux
      ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "/etc/bamos/update-notify-failure.sh";
        StandardOutput = "journal";
        StandardError = "journal";
      };
    };

    systemd.timers."bamos-update" = {
      description = "Bamos auto-update timer (12h)";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "10min";
        OnUnitActiveSec = "12h";
        RandomizedDelaySec = "1h";
      };
    };
  };
}
