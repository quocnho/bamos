#!/usr/bin/env bash
# bam — BamOS CLI v0.4.0
# Universal package manager + selective backup engine
set -euo pipefail

BAM_VERSION="0.4.0"
BACKUP_DIR="/data/backups"
BTRBK_CONF="/etc/btrbk/btrbk.conf"

# Backup subdirs
SYSTEM_DIR="$BACKUP_DIR/system"
HOME_DIR="$BACKUP_DIR/home"
DATA_DIR="$BACKUP_DIR/data"

# Home exclude patterns (cache, temp, app data)
HOME_EXCLUDES=(
  --exclude='.cache'
  --exclude='.npm'
  --exclude='.cargo'
  --exclude='.local/share/flatpak'
  --exclude='.local/share/Trash'
  --exclude='.local/share/Steam'
  --exclude='.local/share/containers'
  --exclude='.var'
  --exclude='.dbus'
  --exclude='.gvfs'
  --exclude='snap'
  --exclude='go/pkg'
  --exclude='.mozilla/firefox/*.default*/cache2'
  --exclude='Downloads/*.iso'
  --exclude='Downloads/*.AppImage'
)

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

usage() { cat << 'EOF'
BamOS CLI v'"$BAM_VERSION"' — Universal package and command manager

Usage: bam <command> [options]

Package:
  install <pkg>     Install package (nix profile + flatpak)
  remove <pkg>      Remove package
  search <query>    Search nixpkgs
  shell <pkg>       Temp shell with package

System:
  run <cmd>         Run binary in FHS environment
  update            Check, confirm, then update: flake + version files + rebuild
  update --check    Only check for available update (no action)
  rollback [gen]    Rollback to previous generation
  changelog         Show changelog of newer versions (from GitHub)
  info              System information
  clean [--keep N]  Clean Btrfs snapshots + Nix generations

Backup & Restore:
  backup [-s] [-h] [-d]    Selective backup (default: -s -h)
  restore [-s] [-h] [-d]   Selective restore (interactive if no flags)
  restore --list           List all backups

Flags:
  -s    System config (/etc/nixos/)
  -h    Home config (~/.config, ~/.local/share, etc.)
  -d    Data volume (/data/)

Examples:
  sudo bam backup              # Backup system + home
  sudo bam backup -s -d        # Backup system + data only
  sudo bam restore -h          # Restore home only
  sudo bam restore --list      # List all backups
  sudo bam update              # Check + confirm + update system
  sudo bam update --check      # Only check for updates
EOF
}

require_root() {
  if [ "$(id -u)" -ne 0 ]; then echo "Need root: sudo bam $*"; exit 1; fi
}

# ─── Ensure backup dirs exist ───
ensure_dirs() {
  mkdir -p "$SYSTEM_DIR" "$HOME_DIR" "$DATA_DIR"
}

# ─── List backups ───
list_backups() {
  ensure_dirs
  echo ""
  echo "=============================="
  echo "  BamOS Backup List"
  echo "=============================="
  echo ""
  local idx=0

  # System config backups
  if [ -d "$SYSTEM_DIR" ]; then
    for f in $(ls -1t "$SYSTEM_DIR/"*.tar.zst 2>/dev/null | head -10); do
      idx=$((idx + 1))
      local d=$(stat -c '%y' "$f" 2>/dev/null | cut -d. -f1)
      printf "  %2d) system | %s | %s\n" "$idx" "$d" "$(basename $f)"
    done
  fi

  # Home config backups
  if [ -d "$HOME_DIR" ]; then
    for f in $(ls -1t "$HOME_DIR/"*.tar.zst 2>/dev/null | head -10); do
      idx=$((idx + 1))
      local d=$(stat -c '%y' "$f" 2>/dev/null | cut -d. -f1)
      printf "  %2d) home   | %s | %s\n" "$idx" "$d" "$(basename $f)"
    done
  fi

  # Data backups
  if [ -d "$DATA_DIR" ]; then
    for f in $(ls -1t "$DATA_DIR/"*.tar.zst 2>/dev/null | head -10); do
      idx=$((idx + 1))
      local d=$(stat -c '%y' "$f" 2>/dev/null | cut -d. -f1)
      printf "  %2d) data   | %s | %s\n" "$idx" "$d" "$(basename $f)"
    done
  fi

  if [ "$idx" -eq 0 ]; then echo "  (no backups — run: sudo bam backup)"; fi
  echo "------------------------------"
  echo "  Total: $idx backups"
  echo ""
}

# ─── Select backup items interactive ───
select_items() {
  local mode="$1"  # "backup" or "restore"
  echo ""
  echo "Select items to $mode (space-separated, e.g. 1 2 3):"
  echo "  1) System config"
  echo "  2) Home config (user data, .config, .local)"
  echo "  3) Data volume"
  echo "  0) All"
  echo ""
  echo -n "Your choice: "
  read -r choices
  echo ""
  for c in $choices; do
    case "$c" in
      0|1) SYSTEM_SELECTED=1 ;;
      0|2) HOME_SELECTED=1 ;;
      0|3) DATA_SELECTED=1 ;;
    esac
  done
}

# ─── Perform backup ───
perform_backup() {
  ensure_dirs
  local timestamp=$(date +%Y%m%d-%H%M%S)
  local system_sel=0 home_sel=0 data_sel=0

  # Parse flags
  if [ $# -eq 0 ]; then
    system_sel=1; home_sel=1
  else
    while getopts "shd" opt; do
      case "$opt" in s) system_sel=1;; h) home_sel=1;; d) data_sel=1;; esac
    done
  fi

  echo "=============================="
  echo "  BamOS Backup"
  echo "=============================="
  echo ""

  local count=0 items=""
  [ "$system_sel" -eq 1 ] && count=$((count + 1)) && items="$items system"
  [ "$home_sel" -eq 1 ] && count=$((count + 1)) && items="$items home"
  [ "$data_sel" -eq 1 ] && count=$((count + 1)) && items="$items data"
  echo "  Items:$items"
  echo ""

  local i=1
  # System config
  if [ "$system_sel" -eq 1 ]; then
    echo "[$i/$count] Backing up system config..."
    local file="$SYSTEM_DIR/nixos-config-$timestamp.tar.zst"
    tar -caf "$file" --exclude='hardware-configuration.nix' -C /etc nixos/ 2>/dev/null
    echo "  Saved: $(basename $file) ($(du -h "$file" | cut -f1))"
    i=$((i + 1))
  fi

  # Home config (selective)
  if [ "$home_sel" -eq 1 ]; then
    echo "[$i/$count] Backing up home config (selective)..."
    local file="$HOME_DIR/home-config-$timestamp.tar.zst"
    for udir in /home/*/; do
      local uname=$(basename "$udir")
      tar -caf "$file" \
        "${HOME_EXCLUDES[@]}" \
        -C /home "$uname/.config" "$uname/.local/share" \
        "$uname/.bashrc" "$uname/.profile" "$uname/.bash_profile" \
        "$uname/.ssh" "$uname/.gnupg" \
        2>/dev/null || true
    done
    if [ -f "$file" ]; then
      echo "  Saved: $(basename $file) ($(du -h "$file" | cut -f1))"
    else
      echo "  (no home config to backup)"
    fi
    i=$((i + 1))
  fi

  # Data volume
  if [ "$data_sel" -eq 1 ] && mountpoint -q /data 2>/dev/null; then
    echo "[$i/$count] Backing up /data..."
    local file="$DATA_DIR/data-backup-$timestamp.tar.zst"
    tar -caf "$file" \
      --exclude='backups' --exclude='.Trash-*' --exclude='lost+found' \
      --exclude='*.iso' --exclude='*.qcow2' \
      -C / data/ 2>/dev/null
    echo "  Saved: $(basename $file) ($(du -h "$file" | cut -f1))"
    i=$((i + 1))
  fi

  echo ""
  echo "Backup completed: $timestamp"
  echo ""
}

# ─── Perform restore ───
perform_restore() {
  ensure_dirs
  local system_sel=0 home_sel=0 data_sel=0
  local has_flags=0

  if [ $# -gt 0 ]; then
    while getopts "shd-:" opt; do
      has_flags=1
      case "$opt" in
        s) system_sel=1 ;;
        h) home_sel=1 ;;
        d) data_sel=1 ;;
        -) case "${OPTARG}" in
             list) list_backups; return ;;
             *) echo "Unknown: --${OPTARG}"; exit 1 ;;
           esac ;;
      esac
    done
  fi

  if [ "$has_flags" -eq 0 ]; then
    list_backups
    return
  fi

  echo "=============================="
  echo "  BamOS Restore"
  echo "=============================="
  echo ""

  [ "$system_sel" -eq 1 ] && local sys_file=$(ls -1t "$SYSTEM_DIR/"*.tar.zst 2>/dev/null | head -1)
  [ "$home_sel" -eq 1 ] && local home_file=$(ls -1t "$HOME_DIR/"*.tar.zst 2>/dev/null | head -1)
  [ "$data_sel" -eq 1 ] && local data_file=$(ls -1t "$DATA_DIR/"*.tar.zst 2>/dev/null | head -1)

  if [ "$system_sel" -eq 1 ] && [ -z "${sys_file:-}" ]; then echo "No system backup found."; system_sel=0; fi
  if [ "$home_sel" -eq 1 ] && [ -z "${home_file:-}" ]; then echo "No home backup found."; home_sel=0; fi
  if [ "$data_sel" -eq 1 ] && [ -z "${data_file:-}" ]; then echo "No data backup found."; data_sel=0; fi

  local count=0
  [ "$system_sel" -eq 1 ] && count=$((count + 1))
  [ "$home_sel" -eq 1 ] && count=$((count + 1))
  [ "$data_sel" -eq 1 ] && count=$((count + 1))

  if [ "$count" -eq 0 ]; then echo "Nothing to restore."; return; fi

  echo "WARNING: This will OVERWRITE current data!"
  echo "Press Ctrl+C to cancel (5s)..."
  sleep 5

  local i=1
  if [ "$system_sel" -eq 1 ]; then
    echo "[$i/$count] Restoring system config..."
    tar -xaf "${sys_file}" -C /etc/nixos/ 2>&1 | tail -2
    echo "  Config restored. Run: sudo nixos-rebuild switch"
    i=$((i + 1))
  fi

  if [ "$home_sel" -eq 1 ]; then
    echo "[$i/$count] Restoring home config..."
    tar -xaf "${home_file}" -C / 2>&1 | tail -2
    echo "  Home config restored."
    i=$((i + 1))
  fi

  if [ "$data_sel" -eq 1 ]; then
    echo "[$i/$count] Restoring /data..."
    tar -xaf "${data_file}" -C / 2>&1 | tail -2
    echo "  /data restored."
    i=$((i + 1))
  fi

  echo ""
  echo "Restore completed!"
}

# ─── Main CLI ───
case "${1:-help}" in
  install)
    shift; [ $# -eq 0 ] && { echo "Usage: bam install <pkg>"; exit 1; }
    for pkg in "$@"; do
      nix profile install "nixpkgs#$pkg" 2>/dev/null && echo "Installed: $pkg (nix)" && continue
      flatpak install flathub "$pkg" 2>/dev/null && echo "Installed: $pkg (flatpak)" && continue
      echo "Failed: $pkg"
    done ;;
  remove)
    shift; [ $# -eq 0 ] && { echo "Usage: bam remove <pkg>"; exit 1; }
    for pkg in "$@"; do
      nix profile remove "$pkg" 2>/dev/null && echo "Removed: $pkg (nix)" && continue
      flatpak uninstall "$pkg" 2>/dev/null && echo "Removed: $pkg (flatpak)" && continue
    done ;;
  search) shift; nix search nixpkgs "$*" 2>&1 | head -20 ;;
  shell) shift; exec nix shell "nixpkgs#$*" -c "${SHELL:-bash}" ;;
  run) shift; exec @fhsEnv@/bin/bam-fhs "$@" ;;
  update)
    require_root "update"
    CHECK_ONLY=0
    case "${2:-}" in --check|-c) CHECK_ONLY=1;; esac

    BAMOS_VERSION_DIR="/etc/bamos"
    LOCAL_VERSION=$(cat "$BAMOS_VERSION_DIR/version" 2>/dev/null || echo "0.0.0")
    REMOTE_VERSION=""
    GITHUB_BASE="https://raw.githubusercontent.com/quocnho/bamos/main"

    echo "=============================="
    echo "  BamOS Update Check"
    echo "=============================="
    echo ""

    # ── Fetch remote version ──
    if command -v curl &>/dev/null; then
      REMOTE_VERSION=$(curl -sfL "$GITHUB_BASE/VERSION" 2>/dev/null || echo "")
    elif command -v wget &>/dev/null; then
      REMOTE_VERSION=$(wget -qO- "$GITHUB_BASE/VERSION" 2>/dev/null || echo "")
    fi

    if [ -z "$REMOTE_VERSION" ]; then
      echo "❌ Cannot reach GitHub. Check your internet connection."
      echo ""
      echo "Local version: $LOCAL_VERSION"
      echo ""
      exit 1
    fi

    echo "  Local:  v$LOCAL_VERSION"
    echo "  Remote: v$REMOTE_VERSION"
    echo ""

    # ── Compare versions ──
    NEWER="$(printf '%s\n%s' "$LOCAL_VERSION" "$REMOTE_VERSION" | sort -V | tail -1)"
    if [ "$NEWER" = "$LOCAL_VERSION" ] && [ "$LOCAL_VERSION" != "$REMOTE_VERSION" ]; then
      echo "⚠ Remote version is OLDER than local. Skipping."
      exit 0
    fi
    if [ "$LOCAL_VERSION" = "$REMOTE_VERSION" ]; then
      echo "✅ Your system is up to date (v$LOCAL_VERSION)."
      exit 0
    fi

    # ── New version available: fetch changelog ──
    echo "📦 New version available: v$LOCAL_VERSION → v$REMOTE_VERSION"
    echo ""
    echo "--- Changelog ---"

    CHANGELOG_TEXT=""
    CHANGELOG_DATA=""
    if command -v curl &>/dev/null; then
      CHANGELOG_DATA=$(curl -sfL "$GITHUB_BASE/CHANGELOG.md" 2>/dev/null || echo "")
    elif command -v wget &>/dev/null; then
      CHANGELOG_DATA=$(wget -qO- "$GITHUB_BASE/CHANGELOG.md" 2>/dev/null || echo "")
    fi

    # Check for pre-fetched update_change from auto-update timer
    if [ -f "$BAMOS_VERSION_DIR/update_change" ] && [ -z "$CHANGELOG_DATA" ]; then
      cat "$BAMOS_VERSION_DIR/update_change"
      CHANGELOG_TEXT="$(cat "$BAMOS_VERSION_DIR/update_change")"
    fi

    if [ -n "$CHANGELOG_DATA" ]; then
      NEW_VERSIONS=$(echo "$CHANGELOG_DATA" | grep -E '^## \[' | sed 's/## \[\([^]]*\)\].*/\1/')
      for ver in $NEW_VERSIONS; do
        if [ "$(printf '%s\n%s' "$LOCAL_VERSION" "$ver" | sort -V | tail -1)" = "$ver" ] && [ "$LOCAL_VERSION" != "$ver" ]; then
          echo ""
          echo "═══ v$ver ═══"
          echo "$CHANGELOG_DATA" | awk -v v="## [$ver]" '
            $0 ~ v {found=1; next}
            found && /^## \[/ {exit}
            found {print}
          ' | head -20
          CHANGELOG_TEXT="${CHANGELOG_TEXT}BamOS $ver
$(echo "$CHANGELOG_DATA" | awk -v v="## [$ver]" '
  $0 ~ v {found=1; next}
  found && /^## \[/ {exit}
  found {print}
' | head -15)

"
        fi
      done
    fi

    echo ""
    echo "---"
    echo ""

    # ── Check-only mode ──
    if [ "$CHECK_ONLY" -eq 1 ]; then
      echo "Use: sudo bam update"
      echo "to apply the update."
      exit 0
    fi

    # ── Ask confirmation ──
    echo -n "Apply update v$LOCAL_VERSION → v$REMOTE_VERSION now? [Y/n]: "
    read -r confirm
    case "$confirm" in
      n|N|no|NO) echo "Cancelled."; exit 0 ;;
      *) echo "Proceeding..." ;;
    esac
    echo ""

    # ── Save update_change ──
    if [ -n "$CHANGELOG_TEXT" ]; then
      echo "$CHANGELOG_TEXT" > "$BAMOS_VERSION_DIR/update_change"
      echo "✅ Update change saved to $BAMOS_VERSION_DIR/update_change"
    fi

    # ── Download version files from GitHub ──
    echo "→ Downloading VERSION from GitHub..."
    # Xóa symlink trước (vì /etc/bamos/version là symlink đến Nix store read-only)
    rm -f "$BAMOS_VERSION_DIR/version" "$BAMOS_VERSION_DIR/CHANGELOG.md" 2>/dev/null || true
    if command -v curl &>/dev/null; then
      curl -sfL "$GITHUB_BASE/VERSION" -o "$BAMOS_VERSION_DIR/version" 2>/dev/null && \
        echo "  ✅ VERSION updated: $(cat "$BAMOS_VERSION_DIR/version")" || \
        echo "  ⚠ Failed to update VERSION"
      curl -sfL "$GITHUB_BASE/CHANGELOG.md" -o "$BAMOS_VERSION_DIR/CHANGELOG.md" 2>/dev/null && \
        echo "  ✅ CHANGELOG.md updated" || \
        echo "  ⚠ Failed to update CHANGELOG.md"
    elif command -v wget &>/dev/null; then
      rm -f "$BAMOS_VERSION_DIR/version" "$BAMOS_VERSION_DIR/CHANGELOG.md" 2>/dev/null || true
      wget -qO "$BAMOS_VERSION_DIR/version" "$GITHUB_BASE/VERSION" 2>/dev/null && \
        echo "  ✅ VERSION updated: $(cat "$BAMOS_VERSION_DIR/version")" || \
        echo "  ⚠ Failed to update VERSION"
      wget -qO "$BAMOS_VERSION_DIR/CHANGELOG.md" "$GITHUB_BASE/CHANGELOG.md" 2>/dev/null && \
        echo "  ✅ CHANGELOG.md updated" || \
        echo "  ⚠ Failed to update CHANGELOG.md"
    fi

    echo ""

    # ── Perform actual Nix update ──
    echo "→ Updating flake in /etc/nixos..."
    nix flake update --flake /etc/nixos 2>&1 | tail -3
    echo "→ Rebuilding system..."
    nixos-rebuild switch --flake /etc/nixos --accept-flake-config 2>&1 | tail -5
    echo "→ Cleaning old generations..."
    nix-collect-garbage --delete-older-than 5d
    # Regen boot menu sau cleanup (GLF-OS pattern)
    nixos-rebuild boot --flake /etc/nixos 2>&1 | tail -1
    echo "✅ System updated to v$(cat "$BAMOS_VERSION_DIR/version")!" ;;
  info)
    echo "=== BamOS $BAM_VERSION ==="
    echo "NixOS $(nixos-version 2>/dev/null || echo '?')"
    @inxi@/bin/inxi -C 2>/dev/null | head -3
    @lspci@ 2>/dev/null | grep -E "VGA|3D" | head -1
    free -h | grep Mem
    df -h / 2>/dev/null | tail -1
    echo "Backups: $(ls -1 "$SYSTEM_DIR" 2>/dev/null | wc -l) system, $(ls -1 "$HOME_DIR" 2>/dev/null | wc -l) home, $(ls -1 "$DATA_DIR" 2>/dev/null | wc -l) data"
    # Check for pending update
    if [ -f /etc/bamos/version ]; then
      local_ver=$(cat /etc/bamos/version)
      echo "BamOS version: $local_ver"
      if [ -f /etc/bamos/update_change ]; then
        remote_ver=$(head -1 /etc/bamos/update_change 2>/dev/null | grep -oP 'v\K[^ ]+' || echo "?")
        echo "⚠ Update available: v$local_ver → v$remote_ver"
        echo "  Run: sudo bam update"
      fi
    fi
    ;;
  clean)
    require_root "clean"
    keep="${2:-5}"
    case "${2:-}" in --keep) keep="${3:-5}"; shift 2;; esac
    nix-collect-garbage --delete-older-than "${keep}d"
    command -v btrbk &>/dev/null && btrbk prune 2>/dev/null || true
    echo "Clean completed!" ;;
  backup)
    require_root "backup"
    shift
    perform_backup "$@"
    list_backups
    ;;
  restore)
    require_root "restore"
    shift
    perform_restore "$@"
    ;;
  rollback)
    require_root "rollback"
    gen="''${2:-}"
    if [ -z "$gen" ]; then
      echo "=== Available generations ==="
      nix-env --list-generations -p /nix/var/nix/profiles/system 2>/dev/null | tail -10
      echo ""
      echo -n "Enter generation number to rollback to (or 0 to cancel): "
      read -r gen
      [ "$gen" -eq 0 ] 2>/dev/null && { echo "Cancelled."; exit 0; }
    fi
    echo "→ Rolling back to generation $gen..."
    nixos-rebuild switch --rollback --flake /etc/nixos 2>&1 | tail -3 || {
      # Fallback: direct profile set
      profile="/nix/var/nix/profiles/system-${gen}-link"
      if [ -L "$profile" ]; then
        nix-env --profile /nix/var/nix/profiles/system --set "$profile"
        /run/current-system/bin/switch-to-configuration switch
        echo "✅ Rolled back to generation $gen"
      else
        echo "❌ Generation $gen not found"
        exit 1
      fi
    }
    ;;

  changelog)
    echo "=== BamOS Changelog ==="
    echo ""
    local_version=$(cat /etc/bamos/version 2>/dev/null || echo "0.0.0")
    echo "Local version: $local_version"
    echo ""

    # Check for pre-fetched update_change from auto-update timer
    if [ -f /etc/bamos/update_change ]; then
      echo "📋 Pending update found!"
      echo "========================"
      cat /etc/bamos/update_change
      echo "========================"
      echo ""
      echo "Run: sudo bam update"
      echo ""
      exit 0
    fi

    echo "Fetching latest changes from GitHub..."
    echo ""
    # Fetch CHANGELOG.md từ GitHub raw
    changelog_url="https://raw.githubusercontent.com/quocnho/bamos/main/CHANGELOG.md"
    if command -v curl &>/dev/null; then
      remote=$(curl -sfL "$changelog_url" 2>/dev/null || true)
    elif command -v wget &>/dev/null; then
      remote=$(wget -qO- "$changelog_url" 2>/dev/null || true)
    fi
    if [ -z "$remote" ]; then
      # Fallback: đọc local
      if [ -f /etc/bamos/CHANGELOG.md ]; then
        remote=$(cat /etc/bamos/CHANGELOG.md)
        echo "(Offline mode — showing local changelog)"
      else
        echo "(No network. Run 'bam update' to fetch latest changelog.)"
        exit 0
      fi
    fi
    # Parse: lấy các section version > local_version
    new_versions=$(echo "$remote" | grep -E '^## \[' | sed 's/## \[\([^]]*\)\].*/\1/')
    found=false
    for ver in $new_versions; do
      if [ "$ver" != "$local_version" ] && [ "$(printf '%s\n%s' "$local_version" "$ver" | sort -V | tail -1)" = "$ver" ]; then
        found=true
        echo ""
        echo "=== New in $ver ==="
        echo "$remote" | awk -v v="## [$ver]" '
          $0 ~ v {found=1; next}
          found && /^## \[/ {exit}
          found {print}
        ' | head -20
      fi
    done
    if [ "$found" = false ]; then
      echo "Your system is up to date!"
    fi
    echo ""
    echo "---"
    echo "Full changelog: https://github.com/quocnho/bamos/blob/main/CHANGELOG.md"
    ;;

  help|--help|-h) usage ;;
  *) echo "Unknown: $1"; usage; exit 1 ;;
esac
