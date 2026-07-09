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
    runtimeInputs = with pkgs; [ nix nixos-rebuild coreutils gnugrep gawk systemd curl ];
    text = ''
            set -euo pipefail

            STATE_DIR="/var/lib/bamos"
            STATE_FILE="$STATE_DIR/last-rebuild-status"
            LOG_FILE="/var/log/bamos-update.log"
            mkdir -p "$STATE_DIR"
            touch "$LOG_FILE" 2>/dev/null || true

            exec > >(tee -a "$LOG_FILE") 2>&1

            BAMOS_VERSION_DIR="/etc/bamos"
            GITHUB_BASE="https://raw.githubusercontent.com/quocnho/bamos/main"

            echo "[$(date)] === BamOS Auto-Update (check only) ==="

            # ── Check for new version ──
            LOCAL_VERSION=$(cat "$BAMOS_VERSION_DIR/version" 2>/dev/null || echo "0.0.0")
            REMOTE_VERSION=""
            if command -v curl &>/dev/null; then
              REMOTE_VERSION=$(curl -sfL "$GITHUB_BASE/VERSION" 2>/dev/null || echo "")
            elif command -v wget &>/dev/null; then
              REMOTE_VERSION=$(wget -qO- "$GITHUB_BASE/VERSION" 2>/dev/null || echo "")
            fi
            if [ -z "$REMOTE_VERSION" ]; then
              echo "[INFO] Cannot reach GitHub — skipping version check"
              echo "ok|no-network" > "$STATE_FILE"
              exit 0
            fi

            # Compare versions
            NEWER="$(printf '%s\n%s' "$LOCAL_VERSION" "$REMOTE_VERSION" | sort -V | tail -1)"
            if [ "$NEWER" = "$LOCAL_VERSION" ] && [ "$LOCAL_VERSION" != "$REMOTE_VERSION" ]; then
              echo "[INFO] Remote version ($REMOTE_VERSION) is older than local ($LOCAL_VERSION)."
              echo "ok|older-remote" > "$STATE_FILE"
              rm -f "$BAMOS_VERSION_DIR/update_change" 2>/dev/null || true
              exit 0
            fi

            if [ "$LOCAL_VERSION" = "$REMOTE_VERSION" ]; then
              echo "[INFO] Version $LOCAL_VERSION is up to date"
              rm -f "$BAMOS_VERSION_DIR/update_change" 2>/dev/null || true
              echo "ok|uptodate" > "$STATE_FILE"
              exit 0
            fi

            # ── New version available ──
            echo "[INFO] New version available: $LOCAL_VERSION → $REMOTE_VERSION"

            # Fetch changelog of new versions
            CHANGELOG_TEXT=""
            CHANGELOG_URL="$GITHUB_BASE/CHANGELOG.md"
            if command -v curl &>/dev/null; then
              CHANGELOG_DATA=$(curl -sfL "$CHANGELOG_URL" 2>/dev/null || echo "")
            elif command -v wget &>/dev/null; then
              CHANGELOG_DATA=$(wget -qO- "$CHANGELOG_URL" 2>/dev/null || echo "")
            fi

            if [ -n "$CHANGELOG_DATA" ]; then
              NEW_VERSIONS=$(echo "$CHANGELOG_DATA" | grep -E '^## \[' | sed 's/## \[\([^]]*\)\].*/\1/')
              for ver in $NEW_VERSIONS; do
                if [ "$(printf '%s\n%s' "$LOCAL_VERSION" "$ver" | sort -V | tail -1)" = "$ver" ] && [ "$LOCAL_VERSION" != "$ver" ]; then
                  CHANGES=$(echo "$CHANGELOG_DATA" | awk -v v="## [$ver]" '
                    $0 ~ v {found=1; next}
                    found && /^## \[/ {exit}
                    found && /^- / {print substr($0,3)}
                    found && /^### / {print}
                  ' | head -15)
                  CHANGELOG_TEXT="''${CHANGELOG_TEXT}BamOS $ver
      ''${CHANGES}

      "
                fi
              done
            fi

            # ── Save update_change file for 'bam update' ──
            mkdir -p "$BAMOS_VERSION_DIR"
            if [ -n "$CHANGELOG_TEXT" ]; then
              echo -e "Update available: $LOCAL_VERSION → $REMOTE_VERSION\n\n$CHANGELOG_TEXT" \
                > "$BAMOS_VERSION_DIR/update_change"
              echo "[INFO] Update changes saved to $BAMOS_VERSION_DIR/update_change"
            fi

            # ── Notify user (desktop notification) ──
            NOTIFY_MSG="BamOS $REMOTE_VERSION Available"
            NOTIFY_BODY="From v$LOCAL_VERSION → v$REMOTE_VERSION"
            if [ -n "$CHANGELOG_TEXT" ]; then
              NOTIFY_BODY="$(echo "$CHANGELOG_TEXT" | head -8)\n\nRun: sudo bam update"
            fi
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
                  "$NOTIFY_MSG" \
                  "$NOTIFY_BODY" 2>/dev/null || true
            done

            # Auto-update only CHECKS and NOTIFIES — does NOT rebuild.
            # User must run 'sudo bam update' to apply interactively.
            echo "[INFO] Update available. Run 'sudo bam update' to apply."
            echo "ok|notified|version=$REMOTE_VERSION" > "$STATE_FILE"
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
    })
  ];
}
