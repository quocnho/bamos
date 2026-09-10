#!/usr/bin/env bash
# Script gắn Cục Xương cho Nautilus (Files Manager)
# Khi click chạy trong Nautilus, tự động nạp đường dẫn thư mục hiện tại vào BamAI Mascot

TARGET_DIR="$NAUTILUS_SCRIPT_CURRENT_URI"
if [ -z "$TARGET_DIR" ]; then
  TARGET_DIR="$PWD"
fi

# Chuyển đổi file:// URI thành đường dẫn chuẩn nếu cần
TARGET_DIR=$(python3 -c "import urllib.parse, sys; print(urllib.parse.unquote(urllib.parse.urlparse(sys.argv[1]).path))" "$TARGET_DIR" 2>/dev/null || echo "$TARGET_DIR")

if [ -z "$TARGET_DIR" ] || [ ! -d "$TARGET_DIR" ]; then
  TARGET_DIR="$PWD"
fi

# Gửi bối cảnh thư mục sang BamAI
if command -v bamos-assistant >/dev/null 2>&1; then
  bamos-assistant --context-dir "$TARGET_DIR" >/dev/null 2>&1 &
elif [ -f "/etc/nixos/pkgs/assistant/main.go" ]; then
  curl -s "http://127.0.0.1:9195/api/context-dir?path=$(python3 -c 'import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))' "$TARGET_DIR")" >/dev/null 2>&1 || true
fi
