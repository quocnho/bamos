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
  switch            Rebuild system: nixos-rebuild switch
  switch --test     Rebuild test (no switch)
  switch --boot     Rebuild + add to boot menu
  switch --flake    Rebuild with custom flake URL
  update            Check, confirm, then update: flake + version files + rebuild
  update --check    Only check for available update (no action)
  rollback [gen]    Rollback to previous generation
  changelog         Show changelog of newer versions (from GitHub)
  info              System information
  clean [--keep N]  Clean Btrfs snapshots + Nix generations

ISO & VM:
  iso [variant]     Build ISO (gnome|kde|cosmic, default: gnome)
  iso --clean       Clean old artifacts + build fresh
  iso --vm          Build + boot in QEMU VM
  iso --vm --disk  G  Set VM disk size (default: 32G)
  vm                Run QEMU VM with latest built ISO
  vm --disk  G      Custom disk size
  vm --ram  G       Custom RAM (default: 4G)
  vm --uefi         Use UEFI (OVMF)
  usb <device>      Write ISO to USB (e.g., /dev/sda)
  usb <device> --iso <path>  Write specific ISO to USB

Backup & Restore:
  backup [-s] [-h] [-d]    Selective backup (default: -s -h)
  restore [-s] [-h] [-d]   Selective restore (interactive if no flags)
  restore --list           List all backups

Snapshot & Share:
  snapshot create [name]  Create portable system snapshot (config+home+data)
  snapshot list           List all snapshots
  snapshot restore <name> Restore from snapshot
  snapshot share <name>   Package snapshot for sharing (tar.zst)
  share export            Export /etc/nixos/ as portable archive
  share iso [variant]     Build custom ISO with current user config baked in

Flags:
  -s    System config (/etc/nixos/)
  -h    Home config (~/.config, ~/.local/share, etc.)
  -d    Data volume (/data/)

Examples:
  bam iso                           # Build GNOME ISO
  bam iso kde --vm                  # Build KDE ISO + boot in VM
  bam vm                            # Boot VM with latest ISO
  bam switch                        # Rebuild system
  bam switch --flake github:quocnho/bamos#lg  # Rebuild from GitHub
  bam usb /dev/sda                  # Write ISO to USB
  bam snapshot create my-backup     # Create portable snapshot
  bam snapshot share my-backup      # Package for sharing
  bam share iso                     # Build custom ISO with my config
  sudo bam backup                   # Backup system + home
  sudo bam update                   # Check + confirm + update system
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

# ═══════════════════════════════════════════════════════════
# Helper functions
# ═══════════════════════════════════════════════════════════

# --- Detect current flake location ---
find_flake() {
  if [ -f /etc/nixos/flake.nix ]; then
    echo "/etc/nixos"
  elif [ -f "${HOME}/Projects/bamos/flake.nix" ]; then
    echo "${HOME}/Projects/bamos"
  else
    echo "/etc/nixos"
  fi
}

# --- Get default ISO variant ---
get_default_variant() {
  echo "gnome"
}

# --- Find latest ISO in result/ ---
find_latest_iso() {
  local dir="${1:-result}"
  local iso
  iso=$(find "$dir" -name "*.iso" -type f 2>/dev/null | head -1)
  echo "$iso"
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

  # ─── System: switch ───
  switch)
    FLAKE=$(find_flake)
    case "${2:-}" in
      --test)  echo "🔄 Testing config..."; sudo nixos-rebuild test --flake "$FLAKE" ;;
      --boot)  echo "🔄 Building + adding to boot menu..."; sudo nixos-rebuild boot --flake "$FLAKE" ;;
      --flake) shift 2; sudo nixos-rebuild switch --flake "$*" ;;
      *)       echo "🔄 Rebuilding system..."; sudo nixos-rebuild switch --flake "$FLAKE" ;;
    esac ;;

  # ─── ISO: build ISO ───
  iso)
    VARIANT="${2:-$(get_default_variant)}"
    CLEAN=false
    BOOT_VM=false
    DISK_SIZE="32G"
    shift

    # Parse options
    while [ $# -gt 0 ]; do
      case "$1" in
        --clean) CLEAN=true; shift ;;
        --vm)    BOOT_VM=true; shift ;;
        --disk)  DISK_SIZE="$2"; shift 2 ;;
        gnome|kde|cosmic) VARIANT="$1"; shift ;;
        *) shift ;;
      esac
    done

    if $CLEAN; then
      echo "🧹 Cleaning old artifacts..."
      rm -rf result iso/ bamos-vm.qcow2 2>/dev/null || true
    fi

    echo "💿 Building ISO: $VARIANT"
    FLAKE=$(find_flake)
    nix build "$FLAKE#iso-$VARIANT" --refresh 2>&1 | tail -5

    if [ $? -ne 0 ]; then
      echo "❌ ISO build failed!"
      exit 1
    fi

    ISO_FILE=$(find_latest_iso)
    if [ -n "$ISO_FILE" ]; then
      echo "✅ ISO ready: $ISO_FILE ($(du -h "$ISO_FILE" | cut -f1))"

      # Copy to iso/ directory
      mkdir -p iso
      cp "$ISO_FILE" iso/
      echo "📂 Copied to: iso/$(basename "$ISO_FILE")"

      if $BOOT_VM; then
        echo ""
        echo "🖳️  Booting VM..."
        if [ ! -f bamos-vm.qcow2 ]; then
          qemu-img create -f qcow2 bamos-vm.qcow2 "$DISK_SIZE"
        fi
        qemu-system-x86_64 -enable-kvm -m 4G -smp 2 \
          -cdrom "$ISO_FILE" \
          -drive file=bamos-vm.qcow2,format=qcow2 \
          -boot d &
        echo "✅ VM started in background (PID: $!)"
      fi
    else
      echo "❌ No ISO file found in build output!"
      exit 1
    fi ;;

  # ─── VM: run QEMU with ISO ───
  vm)
    DISK_SIZE="32G"
    RAM="4G"
    UEFI=false
    shift

    while [ $# -gt 0 ]; do
      case "$1" in
        --disk) DISK_SIZE="$2"; shift 2 ;;
        --ram)  RAM="$2"; shift 2 ;;
        --uefi) UEFI=true; shift ;;
        *) shift ;;
      esac
    done

    # Find ISO
    ISO_FILE=$(find_latest_iso)
    if [ -z "$ISO_FILE" ]; then
      ISO_FILE=$(find iso -name "*.iso" -type f 2>/dev/null | head -1)
    fi

    if [ -z "$ISO_FILE" ]; then
      echo "❌ No ISO found! Build one first: bam iso"
      exit 1
    fi

    echo "📀 ISO: $ISO_FILE ($(du -h "$ISO_FILE" | cut -f1))"

    # Create disk if not exists
    if [ ! -f bamos-vm.qcow2 ]; then
      echo "💾 Creating disk image ($DISK_SIZE)..."
      qemu-img create -f qcow2 bamos-vm.qcow2 "$DISK_SIZE"
    fi

    # Build QEMU command
    QEMU_CMD="qemu-system-x86_64 -enable-kvm -m $RAM -smp 2"
    QEMU_CMD+=" -cdrom \"$ISO_FILE\""
    QEMU_CMD+=" -drive file=bamos-vm.qcow2,format=qcow2"
    if $UEFI; then
      QEMU_CMD+=" -bios ${OVMF:-/run/current-system/sw/share/ovmf/ovmf_x64.bin}"
    fi
    QEMU_CMD+=" -boot d"

    echo "🖳️  Starting VM..."
    echo "   RAM: $RAM | Disk: $DISK_SIZE | UEFI: $UEFI"
    echo ""
    eval "$QEMU_CMD" ;;

  # ─── USB: write ISO to USB ───
  usb)
    DEVICE="${2:-}"
    ISO_FILE=""
    shift

    while [ $# -gt 0 ]; do
      case "$1" in
        --iso) ISO_FILE="$2"; shift 2 ;;
        /dev/*) DEVICE="$1"; shift ;;
        *) shift ;;
      esac
    done

    if [ -z "$DEVICE" ]; then
      echo "❌ Usage: bam usb /dev/sdX [--iso path]"
      echo "⚠️  Available disks:"
      lsblk -d -o NAME,SIZE,TYPE,MOUNTPOINT | grep -E "disk"
      exit 1
    fi

    # Find ISO if not specified
    if [ -z "$ISO_FILE" ]; then
      ISO_FILE=$(find_latest_iso)
      if [ -z "$ISO_FILE" ]; then
        ISO_FILE=$(find iso -name "*.iso" -type f 2>/dev/null | head -1)
      fi
    fi

    if [ -z "$ISO_FILE" ] || [ ! -f "$ISO_FILE" ]; then
      echo "❌ ISO not found! Build one: bam iso"
      exit 1
    fi

    echo "⚠️  WARNING: This will OVERWRITE $DEVICE!"
    echo "📀 ISO: $ISO_FILE ($(du -h "$ISO_FILE" | cut -f1))"
    echo "💾 Device: $DEVICE"
    echo -n "Continue? [y/N]: "
    read -r confirm
    case "$confirm" in
      y|Y|yes|YES)
        echo "💿 Writing ISO to $DEVICE..."
        sudo dd if="$ISO_FILE" of="$DEVICE" bs=4M status=progress conv=fsync
        echo "✅ Done! USB is ready to boot."
        ;;
      *) echo "Cancelled." ;;
    esac ;;

  # ─── Snapshot: create portable system snapshot ───
  snapshot)
    SNAPSHOT_DIR="/data/snapshots"
    mkdir -p "$SNAPSHOT_DIR"

    case "${2:-}" in
      create)
        NAME="${3:-bamos-$(date +%Y%m%d-%H%M%S)}"
        echo "📸 Creating snapshot: $NAME"

        SNAPSHOT_PATH="$SNAPSHOT_DIR/$NAME"
        mkdir -p "$SNAPSHOT_PATH"

        # 1. System config (/etc/nixos/)
        echo "   └─ System config..."
        if [ -d /etc/nixos ]; then
          tar -caf "$SNAPSHOT_PATH/system.tar.zst" \
            --exclude='hardware-configuration.nix' \
            -C /etc nixos/ 2>/dev/null
        fi

        # 2. Home config (~/.config, .local, etc.)
        echo "   └─ Home config..."
        if [ -d /home ]; then
          tar -caf "$SNAPSHOT_PATH/home.tar.zst" \
            -C /home . \
            --exclude='.cache' --exclude='.npm' --exclude='.cargo' \
            --exclude='.local/share/flatpak' --exclude='.local/share/Steam' \
            --exclude='.var' --exclude='snap' --exclude='go/pkg' \
            2>/dev/null || true
        fi

        # 3. Installed packages list
        echo "   └─ Package list..."
        nix profile list 2>/dev/null > "$SNAPSHOT_PATH/nix-profile.txt" || true
        flatpak list --app 2>/dev/null > "$SNAPSHOT_PATH/flatpak-apps.txt" || true

        # 4. System metadata
        echo "   └─ System info..."
        {
          echo "# BamOS Snapshot: $NAME"
          echo "Created: $(date -Iseconds)"
          echo "Hostname: $(hostname)"
          echo "Kernel: $(uname -r)"
          echo "BamOS Version: $(cat /etc/bamos/version 2>/dev/null || echo 'unknown')"
          echo "NixOS Version: $(nixos-version 2>/dev/null || echo 'unknown')"
        } > "$SNAPSHOT_PATH/metadata.txt"

        # Summary
        echo ""
        echo "✅ Snapshot created: $NAME"
        echo "   Location: $SNAPSHOT_PATH"
        du -sh "$SNAPSHOT_PATH"
        echo ""
        echo "📋 Contents:"
        ls -lh "$SNAPSHOT_PATH/"
        echo ""
        echo "💡 Share with: bam snapshot share $NAME" ;;

      list)
        echo "📸 BamOS Snapshots:"
        echo ""
        if [ ! -d "$SNAPSHOT_DIR" ] || [ -z "$(ls -A "$SNAPSHOT_DIR" 2>/dev/null)" ]; then
          echo "   (no snapshots found)"
          exit 0
        fi
        for snap in "$SNAPSHOT_DIR"/*/; do
          name=$(basename "$snap")
          size=$(du -sh "$snap" 2>/dev/null | cut -f1)
          created=$(cat "$snap/metadata.txt" 2>/dev/null | grep "Created:" | cut -d' ' -f2- || echo "unknown")
          echo "   📁 $name"
          echo "      Size: $size | Created: $created"
        done ;;

      restore)
        NAME="${3:-}"
        if [ -z "$NAME" ]; then
          echo "❌ Usage: bam snapshot restore <name>"
          echo "   Run 'bam snapshot list' to see available snapshots."
          exit 1
        fi
        SNAPSHOT_PATH="$SNAPSHOT_DIR/$NAME"
        if [ ! -d "$SNAPSHOT_PATH" ]; then
          echo "❌ Snapshot '$NAME' not found!"
          exit 1
        fi
        echo "⚠️  Restoring snapshot: $NAME"
        echo "   This will overwrite current config!"
        echo -n "Continue? [y/N]: "
        read -r confirm
        case "$confirm" in
          y|Y|yes|YES)
            [ -f "$SNAPSHOT_PATH/system.tar.zst" ] && tar -xaf "$SNAPSHOT_PATH/system.tar.zst" -C / 2>/dev/null && echo "   ✅ System config restored"
            [ -f "$SNAPSHOT_PATH/home.tar.zst" ] && tar -xaf "$SNAPSHOT_PATH/home.tar.zst" -C / 2>/dev/null && echo "   ✅ Home config restored"
            echo "✅ Done! Run 'sudo bam switch' to apply system config."
            ;;
          *) echo "Cancelled." ;;
        esac ;;

      share)
        NAME="${3:-}"
        if [ -z "$NAME" ]; then
          echo "❌ Usage: bam snapshot share <name>"
          exit 1
        fi
        SNAPSHOT_PATH="$SNAPSHOT_DIR/$NAME"
        if [ ! -d "$SNAPSHOT_PATH" ]; then
          echo "❌ Snapshot '$NAME' not found!"
          exit 1
        fi
        ARCHIVE="$SNAPSHOT_DIR/${NAME}.tar.zst"
        echo "📦 Packaging snapshot for sharing..."
        tar -caf "$ARCHIVE" -C "$SNAPSHOT_DIR" "$NAME"
        echo "✅ Share archive: $ARCHIVE ($(du -h "$ARCHIVE" | cut -f1))"
        echo ""
        echo "💡 To restore on another machine:"
        echo "   1. Copy file: scp $ARCHIVE user@other-pc:/tmp/"
        echo "   2. Extract: sudo tar -xaf $ARCHIVE -C /data/snapshots/"
        echo "   3. Restore: sudo bam snapshot restore $NAME"
        echo "   4. Rebuild: sudo bam switch" ;;

      *) echo "Usage: bam snapshot [create|list|restore|share]" ;;
    esac ;;

  # ─── Share: export config for sharing ───
  share)
    SHARE_DIR="/tmp/bamos-share"
    mkdir -p "$SHARE_DIR"

    case "${2:-}" in
      export)
        echo "📦 Exporting /etc/nixos/ config..."
        ARCHIVE="$SHARE_DIR/bamos-config-export.tar.zst"
        if [ -d /etc/nixos ]; then
          tar -caf "$ARCHIVE" \
            --exclude='hardware-configuration.nix' \
            --exclude='result' --exclude='iso' \
            -C /etc nixos/
          echo "✅ Config exported: $ARCHIVE"
          du -h "$ARCHIVE"
          echo ""
          echo "💡 Share with:"
          echo "   scp $ARCHIVE user@friend:/tmp/"
          echo ""
          echo "💡 On friend's machine:"
          echo "   sudo tar -xaf $ARCHIVE -C /"
          echo "   sudo bam switch"
        else
          echo "❌ /etc/nixos/ not found!"
          exit 1
        fi ;;

      iso)
        VARIANT="${3:-$(get_default_variant)}"
        echo "🔨 Building custom ISO with current config..."
        echo "   Variant: $VARIANT"
        echo ""
        echo "⚠️  Custom ISO building requires the BamOS source flake."
        echo "   Building from github:quocnho/bamos..."
        nix build "github:quocnho/bamos#iso-$VARIANT" --refresh 2>&1 | tail -3

        if [ $? -eq 0 ]; then
          ISO_FILE=$(find_latest_iso)
          if [ -n "$ISO_FILE" ]; then
            echo "✅ Custom ISO built: $ISO_FILE"
            mkdir -p iso
            cp "$ISO_FILE" "iso/bamos-custom-$VARIANT-$(date +%Y%m%d).iso"
            echo "📂 Copied to: iso/bamos-custom-$VARIANT-$(date +%Y%m%d).iso"
          fi
        else
          echo "❌ Build failed!"
          exit 1
        fi ;;

      *) echo "Usage: bam share [export|iso]" ;;
    esac ;;
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
          echo "$CHANGELOG_DATA" | awk -v ver="$ver" '
            index($0, "## [" ver "]") == 1 {found=1; next}
            found && /^## \[/ {exit}
            found {print}
          ' | head -20
          CHANGELOG_TEXT="${CHANGELOG_TEXT}BamOS $ver
$(echo "$CHANGELOG_DATA" | awk -v ver="$ver" '
  index($0, "## [" ver "]") == 1 {found=1; next}
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
        echo "$remote" | awk -v ver="$ver" '
          index($0, "## [" ver "]") == 1 {found=1; next}
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
