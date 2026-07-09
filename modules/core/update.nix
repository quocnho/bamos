# modules/core/update.nix
# BamOS auto-upgrade engine — systemd timer + notification
# Tham khảo: GLF-OS update.nix
#
# Cung cấp:
#   - Systemd timer: chạy 1 phút sau boot, lặp lại mỗi 12h
#   - Update script: flake update → rebuild boot → gc → notify
#   - Failure notification
#   - bam.changelog: xem diff closures giữa các generation
#   - bam.rollback: quay lại generation trước
#
{ config, lib, pkgs, ... }:

let
  cfg = config.bamos.update;

  # Script cập nhật tự động
  updateScript = pkgs.writeShellApplication {
    name = "bamos-auto-update";
    runtimeInputs = with pkgs; [ nix nixos-rebuild coreutils gnugrep gawk systemd ];
    text = ''
      set -euo pipefail

      STATE_DIR="/var/lib/bamos"
      STATE_FILE="$STATE_DIR/last-rebuild-status"
      LOG_FILE="/var/log/bamos-update.log"
      mkdir -p "$STATE_DIR"
      touch "$LOG_FILE" 2>/dev/null || true

      exec > >(tee -a "$LOG_FILE") 2>&1

      FLAKE_PATH="/etc/nixos"
      FLAKE_NAME="bamos"
      FLAKE_LOCK_PATH="/etc/nixos/flake.lock"

      echo "[$(date)] === BamOS Auto-Update ==="

      # Check flake.lock exists
      if [ ! -f "$FLAKE_LOCK_PATH" ]; then
        echo "[SKIP] No flake.lock at $FLAKE_PATH — skipping auto-update"
        echo "ok|no-flake" > "$STATE_FILE"
        exit 0
      fi

      # ── Check for new version ──
      LOCAL_VERSION=$(cat /etc/bamos/version 2>/dev/null || echo "0.0.0")
      REMOTE_VERSION=""
      if command -v curl &>/dev/null; then
        REMOTE_VERSION=$(curl -sfL "https://raw.githubusercontent.com/quocnho/bamos/main/VERSION" 2>/dev/null || echo "")
      elif command -v wget &>/dev/null; then
        REMOTE_VERSION=$(wget -qO- "https://raw.githubusercontent.com/quocnho/bamos/main/VERSION" 2>/dev/null || echo "")
      fi
      if [ -n "$REMOTE_VERSION" ] && [ "$(printf '%s\n%s' "$LOCAL_VERSION" "$REMOTE_VERSION" | sort -V | tail -1)" = "$REMOTE_VERSION" ] && [ "$LOCAL_VERSION" != "$REMOTE_VERSION" ]; then
        echo "[INFO] New version available: $LOCAL_VERSION → $REMOTE_VERSION"
        # Fetch changelog of new versions
        CHANGELOG_TEXT=""
        CHANGELOG_URL="https://raw.githubusercontent.com/quocnho/bamos/main/CHANGELOG.md"
        if command -v curl &>/dev/null; then
          CHANGELOG_DATA=$(curl -sfL "$CHANGELOG_URL" 2>/dev/null || echo "")
        elif command -v wget &>/dev/null; then
          CHANGELOG_DATA=$(wget -qO- "$CHANGELOG_URL" 2>/dev/null || echo "")
        fi
        if [ -n "$CHANGELOG_DATA" ]; then
          # Build notification text từ các version mới hơn local
          NEW_VERSIONS=$(echo "$CHANGELOG_DATA" | grep -E '^## \[' | sed 's/## \[\([^]]*\)\].*/\1/')
          for ver in $NEW_VERSIONS; do
            if [ "$(printf '%s\n%s' "$LOCAL_VERSION" "$ver" | sort -V | tail -1)" = "$ver" ] && [ "$LOCAL_VERSION" != "$ver" ]; then
              # Lấy các dòng thay đổi của version này
              CHANGES=$(echo "$CHANGELOG_DATA" | awk -v v="## [$ver]" '
                $0 ~ v {found=1; next}
                found && /^## \[/ {exit}
                found && /^- / {print substr($0,3); count++}
                found && /^### / {print}
              ' | head -15)
              CHANGELOG_TEXT="${CHANGELOG_TEXT}BamOS $ver available!\n${CHANGES}\n\n"
            fi
          done
        fi
        if [ -n "$CHANGELOG_TEXT" ]; then
          # Notify user
          for path in /run/user/*; do
            uid=$(basename "$path")
            user=$(id -nu "$uid" 2>/dev/null) || continue
            [ -z "$user" ] && continue
            runuser -u "$user" -- env \
              XDG_RUNTIME_DIR="/run/user/$uid" \
              DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" \
              notify-send \
                -u normal \
                -a "BamOS-Update" \
                -i "/run/current-system/sw/share/icons/hicolor/scalable/apps/bamos-logo.svg" \
                "BamOS $REMOTE_VERSION Available" \
                "$CHANGELOG_TEXT" 2>/dev/null || true
          done
        fi
      else
        echo "[INFO] Version $LOCAL_VERSION is up to date"
      fi

      # Lấy hash hiện tại
      INITIAL_HASH=$(sha256sum "$FLAKE_LOCK_PATH" | awk '{print $1}')

      # Flake update
      echo "[INFO] Running nix flake update..."
      if ! nix flake update --flake "$FLAKE_PATH" 2>&1; then
        echo "[FAIL] nix flake update failed"
        echo "failed|$(date -Is)|flake-update" > "$STATE_FILE"
        systemd-notify --status=\"Update failed: flake update error\" || true
        exit 1
      fi

      # So sánh hash
      UPDATED_HASH=$(sha256sum "$FLAKE_LOCK_PATH" | awk '{print $1}')

      if [ "$INITIAL_HASH" = "$UPDATED_HASH" ]; then
        echo "[OK] No changes detected. System is up to date."
        echo "ok|uptodate" > "$STATE_FILE"
        exit 0
      fi

      echo "[INFO] Changes detected! Rebuilding..."

      # Rebuild
      if ! nixos-rebuild boot --flake "$FLAKE_PATH#$FLAKE_NAME" --accept-flake-config 2>&1; then
        echo "[FAIL] Rebuild failed"
        echo "failed|$(date -Is)|rebuild-failed" > "$STATE_FILE"
        systemd-notify --status=\"Update failed: rebuild error\" || true
        exit 1
      fi

      # Garbage collect
      echo "[INFO] Cleaning old generations..."
      nix-collect-garbage --delete-older-than 5d 2>&1 || true

      # Ghi trạng thái thành công
      GENERATION=$(readlink /nix/var/nix/profiles/system 2>/dev/null | grep -oP 'system-\K\d+' || echo "?")
      echo "ok|success|generation=$GENERATION" > "$STATE_FILE"

      echo "[OK] Update completed. Generation: $GENERATION"
    '';
  };

  # Script thông báo khi update thất bại
  notifyFailureScript = pkgs.writeShellApplication {
    name = "bamos-update-notify-failure";
    runtimeInputs = with pkgs; [ libnotify shadow coreutils ];
    text = ''
      STATE_FILE="/var/lib/bamos/last-rebuild-status"
      REASON="unknown"
      [ -f "$STATE_FILE" ] && REASON=$(cut -d'|' -f3- "$STATE_FILE" 2>/dev/null || echo "unknown")

      for path in /run/user/*; do
        uid=$(basename "$path")
        user=$(id -nu "$uid" 2>/dev/null) || continue
        [ -z "$user" ] && continue
        runuser -u "$user" -- env \
          XDG_RUNTIME_DIR="/run/user/$uid" \
          DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" \
          notify-send \
            -u critical \
            -a "BamOS-Update" \
            -i "/run/current-system/sw/share/icons/hicolor/scalable/apps/bamos-logo.svg" \
            "BamOS Update - Error" \
            "Auto-update failed: $REASON. See /var/log/bamos-update.log" || true
      done
    '';
  };
in
{
  options.bamos.update = {
    autoUpgrade = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Bật auto-upgrade: flake update + rebuild + gc";
    };

    autoUpgradeInterval = lib.mkOption {
      type = lib.types.str;
      default = "12h";
      description = "Chu kỳ auto-upgrade (systemd timer OnUnitActiveSec)";
    };

    enableNotifications = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Hiển thị notification khi update thành công/thất bại";
    };
  };

  config = lib.mkMerge [
    # ── Current BamOS version (luôn active) ──
    {
      bamos.version.currentVersion = lib.mkDefault (builtins.readFile ../../VERSION);
      environment.etc."bamos/version".text = (builtins.readFile ../../VERSION);
      environment.etc."bamos/CHANGELOG.md".source = ../../CHANGELOG.md;
    }

    # ── Auto-upgrade engine ──
    (lib.mkIf cfg.autoUpgrade {
      # ═══════════════════════════════════════════════════════
      # /etc/bamos/version — version hiện tại
      # ═══════════════════════════════════════════════════════
      environment.etc."bamos/version".text = config.bamos.version.currentVersion;
      environment.etc."bamos/CHANGELOG.md".source = ../../CHANGELOG.md;

      # Garbage collection tự động (GLF-OS pattern)
      nix.gc = {
        automatic = lib.mkDefault true;
        dates = lib.mkDefault "weekly";
        options = lib.mkDefault "--delete-older-than 5d";
      };
      nix.settings.auto-optimise-store = lib.mkDefault true;

      # ═══════════════════════════════════════════════════════
      # Systemd service: auto-update
      # ═══════════════════════════════════════════════════════
      systemd.services.bamos-auto-update = {
        description = "BamOS Auto-Update";
        wantedBy = [ ];
        path = with pkgs; [
          nix
          nixos-rebuild
          coreutils
          gnugrep
          gawk
          systemd
        ];
        onFailure = lib.mkIf cfg.enableNotifications [ "bamos-update-notify-failure.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${updateScript}/bin/bamos-auto-update";
          KillMode = "process";
          StandardOutput = "journal";
          StandardError = "journal";
        };
        unitConfig.OnFailure = lib.mkIf cfg.enableNotifications [ "bamos-update-notify-failure.service" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
      };

      # ═══════════════════════════════════════════════════════
      # Systemd timer: chạy 1 phút sau boot, lặp lại mỗi 12h
      # ═══════════════════════════════════════════════════════
      systemd.timers.bamos-auto-update = {
        description = "BamOS Auto-Update Timer";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "1min";
          OnUnitActiveSec = cfg.autoUpgradeInterval;
          RandomizedDelaySec = 300;
        };
      };

      # ═══════════════════════════════════════════════════════
      # Failure notification service
      # ═══════════════════════════════════════════════════════
      systemd.services.bamos-update-notify-failure = lib.mkIf cfg.enableNotifications {
        description = "BamOS Update Failure Notification";
        path = with pkgs; [ libnotify shadow coreutils util-linux ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${notifyFailureScript}/bin/bamos-update-notify-failure";
        };
      };
    };
    }
