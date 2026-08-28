#!/usr/bin/env bash
# ============================================================================
#  bam — BamOS CLI
#  Công cụ dòng lệnh quản lý hệ điều hành BamOS (NixOS + Flakes):
#  cập nhật, rebuild (switch/boot/build), build ISO, dọn rác, thông tin...
#
#  Chạy `bam help` để xem danh sách lệnh.
#  Dùng chung cho cả máy dev (host lg) lẫn máy đích cài từ ISO (host bamos):
#  host được tự dò, có thể ghi đè bằng env BAM_HOST / BAM_FLAKE_DIR.
# ============================================================================
set -euo pipefail

PROG="bam"
VERSION="1.1.0"

# Thư mục chứa flake (mặc định: /etc/nixos — repo bamos hoặc flake máy đích)
FLAKE_DIR="${BAM_FLAKE_DIR:-/etc/nixos}"

# ---------- Màu (tắt khi không phải terminal hoặc NO_COLOR) ----------
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  C_RESET=$'\033[0m'
  C_BOLD=$'\033[1m'
  C_RED=$'\033[31m'
  C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'
  C_CYAN=$'\033[36m'
else
  C_RESET=""
  C_BOLD=""
  C_RED=""
  C_GREEN=""
  C_YELLOW=""
  C_CYAN=""
fi

# ---------- In ấn ----------
say()  { printf '%s\n' "$*"; }
info() { printf '%s\n' "${C_CYAN}==>${C_RESET} $*"; }
ok()   { printf '%s\n' "${C_GREEN}[OK]${C_RESET} $*"; }
warn() { printf '%s\n' "${C_YELLOW}[!]${C_RESET} $*"; }
err()  { printf '%s\n' "${C_RED}[X]${C_RESET} $*" >&2; }
die()  { err "$*"; exit 1; }

# ---------- Quyền root ----------
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  SUDO="sudo"
fi

# Chạy lại qua sudo nếu chưa phải root (giữ nguyên toàn bộ tham số).
need_root() {
  if [ "$(id -u)" -ne 0 ]; then
    warn "Lệnh cần quyền root — chạy lại qua sudo..."
    exec sudo "$0" "$@"
  fi
}

# Có yêu cầu xem trợ giúp (-h/--help) không? (chạy trước need_root để không hỏi mật khẩu)
help_requested() {
  local a
  for a in "$@"; do
    if [ "$a" = "-h" ] || [ "$a" = "--help" ]; then
      return 0
    fi
  done
  return 1
}

NIX_FLAGS="nix-command flakes"

# ---------- Dò host trong flake (lg / bamos) ----------
detect_host() {
  if [ -n "${BAM_HOST:-}" ]; then
    printf '%s\n' "$BAM_HOST"
    return
  fi
  local h
  h=$(hostname 2>/dev/null || true)
  case "$h" in
    lg | bamos)
      printf '%s\n' "$h"
      return
      ;;
  esac
  if [ -f "$FLAKE_DIR/flake.nix" ]; then
    local m
    m=$(grep -oE 'nixosConfigurations\.(lg|bamos)' "$FLAKE_DIR/flake.nix" 2>/dev/null | head -n 1 | cut -d. -f2 || true)
    if [ -n "$m" ]; then
      printf '%s\n' "$m"
      return
    fi
  fi
  printf '%s\n' "bamos"
}

flake_exists() {
  [ -f "$FLAKE_DIR/flake.nix" ] || die "Không tìm thấy $FLAKE_DIR/flake.nix — hãy chạy trên máy đã cài BamOS (hoặc đặt BAM_FLAKE_DIR)."
}

# Uptime đẹp (ngày/giờ/phút) — không dựa vào `uptime -p` (không phải máy nào cũng có)
system_uptime() {
  local secs days hours mins
  secs=$(awk '{printf "%d", $1}' /proc/uptime 2>/dev/null || echo 0)
  days=$((secs / 86400))
  secs=$((secs % 86400))
  hours=$((secs / 3600))
  mins=$(((secs % 3600) / 60))
  if [ "$days" -gt 0 ]; then
    printf '%d ngày %d giờ %d phút' "$days" "$hours" "$mins"
  elif [ "$hours" -gt 0 ]; then
    printf '%d giờ %d phút' "$hours" "$mins"
  else
    printf '%d phút' "$mins"
  fi
}

# ---------- Rebuild (switch/boot/build/dry-build) ----------
rebuild() {
  flake_exists
  local action="$1" host tag
  host=$(detect_host)
  if [ "$action" = "switch" ] || [ "$action" = "boot" ]; then
    # Tự gắn tag "NixOS-YY.MM.DD-HH:MM" (nixpkgs chỉ cho ký tự [a-zA-Z0-9:_.-]
    # nên "/" → "." — hosts/lg.nix đọc NIXOS_TAG qua system.nixos.tags).
    tag="NixOS-$(date +%y.%m.%d-%H:%M)"
    info "Rebuild ($action) host '$host' — tag $tag"
    $SUDO env NIXOS_TAG="$tag" nixos-rebuild "$action" --flake "$FLAKE_DIR#$host" --impure
  else
    info "Rebuild ($action) host '$host'..."
    $SUDO nixos-rebuild "$action" --flake "$FLAKE_DIR#$host"
  fi
  ok "Hoàn tất — xem thông tin: bam info"
}

# ---------- Kiểm tra mạng / dung lượng ----------
check_network() {
  if command -v nm-online >/dev/null 2>&1 && nm-online -q --timeout 5 >/dev/null 2>&1; then
    return 0
  fi
  if ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1 || ping -c 1 -W 2 api.github.com >/dev/null 2>&1; then
    return 0
  fi
  warn "Không thấy kết nối internet — nếu tải cấu hình từ GitHub thất bại, hãy kiểm tra mạng rồi thử lại."
}

check_disk() {
  local avail_kb avail_gb
  avail_kb=$(df -k /nix/store | awk 'NR==2 {print $4}')
  avail_gb=$((avail_kb / 1024 / 1024))
  if [ "$avail_gb" -lt 5 ]; then
    die "Dung lượng /nix/store chỉ còn ${avail_gb}GB (< 5GB) — không đủ để cập nhật. Dọn rác trước: bam gc"
  fi
  ok "Dung lượng /nix/store: ${avail_gb}GB trống (đủ)"
}

# Lấy short-rev của input $1 (vd: bamos) từ flake.lock — rỗng nếu không có input đó.
# Máy đích (cài từ ISO) có input `bamos = github:quocnho/bamos/main` trong
# /etc/nixos/flake.nix → rev này chính là phiên bản cấu hình đang dùng.
lock_rev() {
  local name="$1"
  awk -v name="\"$name\":" '
    $0 ~ name { found = 1 }
    found && /"rev":/ {
      gsub(/[",]/, "", $2)
      print substr($2, 1, 7)
      exit
    }
  ' "$FLAKE_DIR/flake.lock" 2>/dev/null || true
}

# ---------- Cập nhật flake.lock (tải cấu hình mới nhất từ GitHub) ----------
update_lockfile() {
  flake_exists
  info "Tải cấu hình mới nhất từ GitHub (nix flake update)..."
  local before after owner
  before=$(lock_rev bamos)
  # Nhớ owner gốc của flake.lock (máy dev: user quocnho; máy đích: root) —
  # khi chạy bằng root, khôi phục lại sau khi update để không đổi chủ sở hữu.
  owner=$(stat -c %U:%G "$FLAKE_DIR/flake.lock" 2>/dev/null || true)
  nix --extra-experimental-features "$NIX_FLAGS" flake update --flake "$FLAKE_DIR"
  if [ -n "$owner" ] && [ "$(id -u)" -eq 0 ]; then
    chown "$owner" "$FLAKE_DIR/flake.lock" 2>/dev/null || true
  fi
  after=$(lock_rev bamos)
  if [ -n "$after" ]; then
    if [ -n "$before" ] && [ "$before" != "$after" ]; then
      ok "Có bản mới từ GitHub: bamos ${before} → ${after} (main)"
    else
      ok "Bamos đang ở phiên bản mới nhất (@ ${after})"
    fi
  else
    ok "flake.lock đã được cập nhật."
  fi
}

# Chỉ cập nhật flake.lock, không rebuild (dành cho người muốn kiểm soát thủ công)
cmd_lock() {
  flake_exists
  update_lockfile
}

# ---------- Cập nhật hệ thống: tải config mới nhất từ GitHub + rebuild ----------
cmd_update() {
  help_requested "$@" && { cmd_help update; return; }
  need_root "$@"
  local boot_only=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --boot) boot_only=1 ;; # rebuild boot — áp dụng khi khởi động lại (an toàn hơn)
      -h | --help) cmd_help update; return ;;
      *) die "Tùy chọn không hợp lệ: $1 (xem: bam help update)" ;;
    esac
    shift
  done
  check_network
  update_lockfile
  check_disk
  if [ "$boot_only" -eq 1 ]; then
    rebuild boot
    ok "Đã cập nhật — thay đổi sẽ áp dụng khi bạn khởi động lại máy."
  else
    rebuild switch
    ok "Cập nhật hoàn tất — hệ thống đang chạy cấu hình mới nhất từ GitHub."
  fi
}

# ---------- Lệnh chính ----------
cmd_switch() {
  help_requested "$@" && { cmd_help switch; return; }
  need_root "$@"
  local update=0
  while [ $# -gt 0 ]; do
    case "$1" in
      -u | --update) update=1 ;;
      -h | --help) cmd_help switch; return ;;
      *) die "Tùy chọn không hợp lệ: $1 (xem: bam help switch)" ;;
    esac
    shift
  done
  if [ "$update" -eq 1 ]; then
    update_lockfile
  fi
  rebuild switch
}

cmd_boot() {
  help_requested "$@" && { cmd_help boot; return; }
  need_root "$@"
  local update=0
  while [ $# -gt 0 ]; do
    case "$1" in
      -u | --update) update=1 ;;
      -h | --help) cmd_help boot; return ;;
      *) die "Tùy chọn không hợp lệ: $1 (xem: bam help boot)" ;;
    esac
    shift
  done
  if [ "$update" -eq 1 ]; then
    update_lockfile
  fi
  rebuild boot
}

cmd_build() {
  rebuild build
}

cmd_dry() {
  rebuild dry-build
}

cmd_iso() {
  flake_exists
  local out iso
  info "Build ISO cài đặt (nix build .#iso)..."
  out=$(cd "$FLAKE_DIR" && nix --extra-experimental-features "$NIX_FLAGS" build .#iso --no-link --print-out-paths 2>&1 | tail -n 1)
  iso=$(ls "$out"/iso/*.iso 2>/dev/null | head -n 1 || true)
  if [ -z "$iso" ]; then
    warn "Build xong nhưng không tìm thấy file .iso trong $out/iso"
    return
  fi
  say ""
  ok "Đã tạo ISO: $(basename "$iso")"
  say "    $iso"
  say ""
  info "Ghi ra USB (thay sdX bằng đúng ổ của bạn):"
  say "    sudo dd if=$iso of=/dev/sdX bs=4M status=progress && sync"
}

cmd_rollback() {
  help_requested "$@" && { cmd_help rollback; return; }
  need_root "$@"
  flake_exists
  local host
  host=$(detect_host)
  info "Quay về generation trước (rollback)..."
  $SUDO nixos-rebuild switch --rollback --flake "$FLAKE_DIR#$host"
  ok "Đã quay về generation trước."
}

cmd_generations() {
  flake_exists
  local gen current n d mark last2
  gen=$(ls -d1v /nix/var/nix/profiles/system-*-link 2>/dev/null || true)
  if [ -z "$gen" ]; then
    die "Không có generation nào (/nix/var/nix/profiles/system-*-link)."
  fi
  current=$(readlink /nix/var/nix/profiles/system 2>/dev/null | grep -o 'system-[0-9]*' || true)
  info "Danh sách generation:"
  # shellcheck disable=SC2086 -- cần word-split cho danh sách đường dẫn
  for p in $gen; do
    n=$(basename "$p" | grep -o '[0-9]*' || echo '?')
    d=$(date -d "@$(stat -c %Y "$p")" '+%Y-%m-%d %H:%M' 2>/dev/null || echo '?')
    mark=""
    [ "$n" = "${current#system-}" ] && mark=" ← hiện tại"
    printf '  %-12s %s%s\n' "system-$n" "$d" "$mark"
  done
  last2=$(printf '%s\n' "$gen" | tail -n 2)
  if [ "$(printf '%s\n' "$last2" | sed '/^$/d' | wc -l)" -ge 2 ]; then
    say ""
    info "Khác biệt giữa 2 generation gần nhất:"
    # shellcheck disable=SC2086 -- last2 là 2 đường dẫn, cần word-split
    nix --extra-experimental-features "$NIX_FLAGS" store diff-closures $last2
  fi
}

cmd_gc() {
  help_requested "$@" && { cmd_help gc; return; }
  need_root "$@"
  local days="${1:-7}"
  case "$days" in
    '' | *[!0-9]*) die "Số ngày không hợp lệ: $days (vd: bam gc 7)" ;;
  esac
  info "Dọn rác /nix/store — giữ generation ${days} ngày..."
  $SUDO nix-collect-garbage --delete-older-than "${days}d"
  # Bài học từ GLF-OS (#189): sau GC, boot menu có thể trỏ vào kernel đã bị
  # xóa — rebuild boot để sinh lại boot menu theo các generation còn sống.
  info "Đồng bộ lại boot menu (nixos-rebuild boot)..."
  rebuild boot
  ok "Dọn rác xong."
}

cmd_info() {
  flake_exists
  local host ver kernel uptime gpu mem disk gen bref
  host=$(detect_host)
  if git -C "$FLAKE_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    ver="$(git -C "$FLAKE_DIR" log -1 --format='%h' 2>/dev/null || echo '?') (branch $(git -C "$FLAKE_DIR" branch --show-current 2>/dev/null || echo '?'))"
  else
    # Máy đích: hiển thị đúng phiên bản cấu hình đang dùng từ GitHub
    bref=$(lock_rev bamos)
    if [ -n "$bref" ]; then
      ver="bamos @ ${bref} (github:quocnho/bamos/main)"
    else
      ver="1.0.0 (config từ github:quocnho/bamos)"
    fi
  fi
  kernel=$(uname -r)
  uptime=$(system_uptime)
  gpu=$(lspci 2>/dev/null | grep -Ei 'vga|3d' | sed 's/^[0-9a-f:.]* //' | head -n 2 | tr '\n' ' | ' | sed 's/ | $//' || true)
  [ -z "$gpu" ] && gpu="?"
  mem=$(free -h | awk '/^Mem:/ {print $3 " / " $2}')
  disk=$(df -h / | awk 'NR==2 {print $3 " đã dùng, " $4 " trống (" $5 ")"}')
  gen=$(readlink /nix/var/nix/profiles/system 2>/dev/null | grep -o 'system-[0-9]*' || true)
  [ -z "$gen" ] && gen="?"
  say ""
  say "${C_BOLD}BamOS${C_RESET} — ${C_CYAN}${C_BOLD}${host}${C_RESET}  (version: ${ver})"
  say "─────────────────────────────────────────────"
  printf '%-14s %s\n' "Kernel:" "$kernel"
  printf '%-14s %s\n' "Uptime:" "$uptime"
  printf '%-14s %s\n' "GPU:" "$gpu"
  printf '%-14s %s\n' "RAM:" "$mem"
  printf '%-14s %s\n' "Disk /:" "$disk"
  printf '%-14s %s\n' "Generation:" "$gen"
  say ""
}

cmd_doctor() {
  flake_exists
  local warncount=0
  local avail_kb avail_gb gen branch dirty lock_age_days
  say "${C_BOLD}Kiểm tra sức khỏe BamOS${C_RESET}"
  say ""
  # 1. Flake
  if [ -f "$FLAKE_DIR/flake.nix" ]; then
    ok "Tìm thấy flake tại $FLAKE_DIR"
  else
    err "Thiếu $FLAKE_DIR/flake.nix"
    warncount=$((warncount + 1))
  fi
  # 2. Dung lượng /nix/store (tối thiểu 5GB như GLF-OS)
  avail_kb=$(df -k /nix/store | awk 'NR==2 {print $4}')
  avail_gb=$((avail_kb / 1024 / 1024))
  if [ "$avail_gb" -ge 5 ]; then
    ok "Dung lượng /nix/store: ${avail_gb}GB trống (đủ)"
  else
    warn "Dung lượng /nix/store chỉ còn ${avail_gb}GB — nên dọn rác: bam gc"
    warncount=$((warncount + 1))
  fi
  # 3. Generation hệ thống
  if [ -e /nix/var/nix/profiles/system ]; then
    gen=$(readlink /nix/var/nix/profiles/system | grep -o 'system-[0-9]*' || true)
    ok "Generation hiện tại: ${gen:-?}"
  else
    warn "Chưa có generation hệ thống (máy mới cài?)"
    warncount=$((warncount + 1))
  fi
  # 4. flake.lock cũ chưa?
  if [ -f "$FLAKE_DIR/flake.lock" ]; then
    lock_age_days=$((($(date +%s) - $(stat -c %Y "$FLAKE_DIR/flake.lock")) / 86400))
    if [ "$lock_age_days" -gt 30 ]; then
      warn "flake.lock đã ${lock_age_days} ngày — chạy: bam update"
      warncount=$((warncount + 1))
    else
      ok "flake.lock còn mới (${lock_age_days} ngày)"
    fi
  fi
  # 5. Git (máy dev)
  if git -C "$FLAKE_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    branch=$(git -C "$FLAKE_DIR" branch --show-current 2>/dev/null || echo '?')
    dirty=$(git -C "$FLAKE_DIR" status --porcelain 2>/dev/null | wc -l)
    if [ "$dirty" -eq 0 ]; then
      ok "Git: branch '$branch' sạch"
    else
      warn "Git: branch '$branch' có $dirty file chưa commit — xem: git status"
      warncount=$((warncount + 1))
    fi
  fi
  say ""
  if [ "$warncount" -gt 0 ]; then
    warn "$warncount điểm cần lưu ý — xem 'bam help' để xử lý."
  else
    ok "Mọi thứ đều ổn. Chúc bạn dùng BamOS vui vẻ!"
  fi
}

# ---------- Máy dev: commit → merge develop→main → push ----------
cmd_publish() {
  if ! git -C "$FLAKE_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    die "Không phải git repo — 'bam publish' chỉ dùng trên máy dev."
  fi
  local msg="$*"
  if [ -z "$msg" ]; then
    die 'Thiếu nội dung commit. Cách dùng: bam publish "nội dung mô tả"'
  fi
  local cur ans
  cur=$(git -C "$FLAKE_DIR" branch --show-current)
  if [ "$cur" != "develop" ]; then
    die "Bạn đang ở branch '$cur' — 'bam publish' chỉ chạy từ branch develop."
  fi
  say "Sẽ thực hiện trên $FLAKE_DIR:"
  say "  1. git add -A + commit \"$msg\" (trên develop)"
  say "  2. checkout main + merge develop"
  say "  3. push origin main + push origin develop"
  say "  4. quay lại develop"
  printf 'Tiếp tục? [y/N] '
  if ! read -r ans; then
    say ""
    say "Hủy."
    return 0
  fi
  case "$ans" in
    y | Y | yes | YES) ;;
    *)
      say "Hủy."
      return 0
      ;;
  esac
  (
    cd "$FLAKE_DIR"
    git add -A
    GIT_EDITOR=true git commit -m "$msg"
    git checkout main
    git merge develop --no-edit
    git push origin main
    git push origin develop
    git checkout develop
  )
  ok "Đã commit, merge develop → main và push lên GitHub."
}

# ---------- Trợ giúp ----------
cmd_help() {
  local topic="${1:-}"
  case "$topic" in
    "")
      say "${C_BOLD}bam — BamOS CLI (v$VERSION)${C_RESET}"
      say ""
      say "Cách dùng: bam <lệnh> [tùy chọn]"
      say ""
      say "${C_BOLD}Lệnh chính:${C_RESET}"
      say "  switch [-u]    Cập nhật hệ thống (rebuild switch, tự gắn tag NixOS-YY.MM.DD-HH:MM)"
      say "  boot [-u]      Như switch nhưng giữ hệ thống đang chạy (áp dụng khi khởi động lại)"
      say "  build          Build thử cấu hình mới, không áp dụng"
      say "  dry            Xem trước những gì sẽ thay đổi (dry-build)"
      say "  update [--boot] Tải cấu hình mới nhất từ GitHub + cập nhật hệ thống ngay"
      say "  lock           Chỉ cập nhật flake.lock (không rebuild)"
      say "  iso            Build file ISO cài đặt cho người dùng khác"
      say "  rollback       Quay về generation trước"
      say "  generations    Danh sách generation + khác biệt 2 bản gần nhất"
      say "  gc [số ngày]   Dọn rác /nix/store (mặc định giữ 7 ngày)"
      say "  info           Thông tin hệ thống (host, kernel, phần cứng...)"
      say "  doctor         Kiểm tra sức khỏe hệ thống"
      say "  publish \"msg\"   (máy dev) commit → merge develop→main → push GitHub"
      say "  version        Phiên bản bam CLI"
      say "  help [lệnh]    Hướng dẫn chi tiết từng lệnh"
      say ""
      say "${C_BOLD}Môi trường:${C_RESET} BAM_FLAKE_DIR (thư mục flake) • BAM_HOST (tên host) • NO_COLOR (tắt màu)"
      say ""
      say "Ví dụ: bam switch -u   •   bam gc 7   •   bam iso   •   bam doctor"
      ;;
    switch | boot | build | dry | update | lock | iso | rollback | generations | gc | info | doctor | publish)
      say "${C_BOLD}Lệnh: bam $topic${C_RESET}"
      case "$topic" in
        switch) say "Rebuild + áp dụng ngay cấu hình mới. -u/--update: chạy nix flake update trước." ;;
        boot) say "Rebuild nhưng chỉ áp dụng khi khởi động lại. -u/--update: cập nhật trước." ;;
        build) say "Build thử cấu hình mới (không ảnh hưởng hệ thống)." ;;
        dry) say "Dry-build: xem trước thay đổi của generation mới." ;;
        update) say "Lệnh cập nhật chính thức: tải cấu hình mới nhất từ GitHub (nix flake update) rồi rebuild switch. --boot: chỉ rebuild boot, áp dụng khi khởi động lại (an toàn hơn)." ;;
        lock) say "Chỉ cập nhật flake.lock (input nixpkgs, bamos...) — không rebuild. Dùng khi bạn tự rebuild thủ công." ;;
        iso) say "Build ISO cài đặt (nix build .#iso), in đường dẫn + cách ghi USB." ;;
        rollback) say "Quay về generation trước đó." ;;
        generations) say "Liệt kê generation + diff 2 bản gần nhất (giống glf-history)." ;;
        gc) say "Dọn rác /nix/store giữ N ngày (mặc định 7) + đồng bộ boot menu. Vd: bam gc 7" ;;
        info) say "In thông tin hệ thống: host, phiên bản, kernel, GPU, RAM, disk, generation." ;;
        doctor) say "Kiểm tra: flake, dung lượng /nix/store, generation, flake.lock, git." ;;
        publish) say "Máy dev: git add → commit → checkout main → merge develop → push cả 2 branch (yêu cầu đang ở develop)." ;;
      esac
      ;;
    *)
      die "Không có trợ giúp cho: $topic (xem: bam help)"
      ;;
  esac
}

# ---------- Điều phối ----------
main() {
  local cmd="${1:-help}"
  if [ $# -gt 0 ]; then
    shift
  fi
  case "$cmd" in
    help | -h | --help) cmd_help "$@" ;;
    switch) cmd_switch "$@" ;;
    boot) cmd_boot "$@" ;;
    build) cmd_build "$@" ;;
    dry | dry-build) cmd_dry "$@" ;;
    update) cmd_update "$@" ;;
    lock) cmd_lock "$@" ;;
    iso) cmd_iso "$@" ;;
    rollback) cmd_rollback "$@" ;;
    gen | generations | history) cmd_generations "$@" ;;
    gc | clean) cmd_gc "$@" ;;
    info | systeminfo) cmd_info "$@" ;;
    doctor | health | check) cmd_doctor "$@" ;;
    publish) cmd_publish "$@" ;;
    host) detect_host ;;
    version | -V | --version) say "bam $VERSION — BamOS CLI" ;;
    *)
      err "Không biết lệnh '$cmd' — chạy 'bam help' để xem danh sách lệnh."
      exit 1
      ;;
  esac
}

main "$@"
