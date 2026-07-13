# pkgs/bam-welcome/default.nix
# BamOS Welcome Banner — Hiển thị khi mở terminal
# Cung cấp thông tin hệ thống + hướng dẫn bam CLI
{ lib, stdenvNoCC, bamos-branding }:

stdenvNoCC.mkDerivation {
  pname = "bam-welcome";
  version = "1.0.0";

  buildCommand = ''
    mkdir -p $out/bin

    cat > $out/bin/bam-welcome << 'WELCOMEEOF'
    #!/usr/bin/env bash
    # BamOS Welcome Banner
    # Hiển thị khi người dùng mở terminal

    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
    BLUE='\033[0;34m'; CYAN='\033[0;36m'; MAGENTA='\033[0;35m'
    BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

    # Chỉ hiển thị khi terminal tương tác
    if [ ! -t 0 ]; then exit 0; fi

    # Chỉ hiển thị 1 lần mỗi ngày (dùng timestamp cache)
    CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/bamos"
    CACHE_FILE="$CACHE_DIR/last-welcome"
    TODAY=$(date +%Y%m%d)
    mkdir -p "$CACHE_DIR"
    if [ -f "$CACHE_FILE" ] && [ "$(cat "$CACHE_FILE")" = "$TODAY" ]; then
      exit 0
    fi
    echo "$TODAY" > "$CACHE_FILE"

    # ─── Header ───
    echo ""
    echo -e "  ${GREEN}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "  ${GREEN}║          ${BOLD}⚡ BamOS${NC}${GREEN} — NixOS cho người Việt        ║${NC}"
    echo -e "  ${GREEN}╚══════════════════════════════════════════════════╝${NC}"
    echo ""

    # ─── System Info ───
    VERSION=$(cat /etc/bamos/version 2>/dev/null || echo "unknown")
    KERNEL=$(uname -r 2>/dev/null || echo "unknown")
    HOSTNAME=$(hostname 2>/dev/null || echo "unknown")
    UPTIME=$(uptime -p 2>/dev/null | sed 's/up //' || echo "unknown")
    NIXOS=$(nixos-version 2>/dev/null || echo "unknown")

    echo -e "  ${DIM}Hostname:${NC} $HOSTNAME"
    echo -e "  ${DIM}BamOS:${NC}    ${GREEN}v$VERSION${NC}"
    echo -e "  ${DIM}NixOS:${NC}    $NIXOS"
    echo -e "  ${DIM}Kernel:${NC}   $KERNEL"
    echo -e "  ${DIM}Uptime:${NC}   $UPTIME"
    echo ""

    # ─── Check update ───
    if [ -f "/etc/bamos/update_change" ]; then
      echo -e "  ${YELLOW}📦 Update available! Run:${NC} sudo bam update"
      echo ""
    fi

    # ─── bam CLI Guide (end-user) ───
    echo -e "  ${BOLD}📋 Hướng dẫn nhanh — BamOS CLI${NC}"
    echo -e "  ─────────────────────────────────────────────"
    echo -e "  ${GREEN}bam info${NC}           Xem thông tin máy"
    echo -e "  ${GREEN}bam install <app>${NC}  Cài ứng dụng (VD: bam install firefox)"
    echo -e "  ${GREEN}bam search <app>${NC}   Tìm ứng dụng"
    echo -e "  ${GREEN}sudo bam update${NC}     Cập nhật hệ thống"
    echo -e "  ${GREEN}sudo bam backup${NC}     Sao lưu dữ liệu"
    echo -e "  ${GREEN}sudo bam switch${NC}     Áp dụng thay đổi"
    echo -e "  ${GREEN}bam --help${NC}         Xem tất cả lệnh"
    echo ""
    echo -e "  ${DIM}💡 Mẹo: Gõ ${NC}bam --help${DIM} để xem đầy đủ tính năng${NC}"
    echo -e "  ${DIM}📖 Tài liệu:${NC} ${DIM}https://bamos.io${NC}"
    echo ""
    WELCOMEEOF

    chmod +x $out/bin/bam-welcome
  '';

  meta = {
    description = "BamOS welcome banner — system info + bam CLI guide on terminal start";
    homepage = "https://github.com/quocnho/bamos";
    license = lib.licenses.mit;
  };
}
