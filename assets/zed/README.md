# Zed editor — Cấu hình chuyên nghiệp (assets)

Cấu hình chuẩn cho **Zed** (bản 1.16, binary `zeditor`) — lưu trong repo để tái lập.

## Cấu trúc

```
assets/zed/
├── settings.json   # Font 17/18 (JetBrainsMono Nerd Font Mono), theme One Dark,
│                   #   autosave, format-on-save, context_servers (MCP)...
└── skills/         # Agent skills (SKILL.md, chuẩn Agent Skills):
    ├── php-laravel/        # artisan, migration, Eloquent, queue, Pint, xdebug
    ├── php-codeigniter/    # spark, model, migration, Query Builder, validation
    ├── mysql-database/     # schema, index, EXPLAIN, transaction, backup
    ├── typescript-node-pwa/ # tsconfig, pnpm, ESM, vitest, manifest, service worker
    ├── flutter-dev/        # analyze/test/build, state management, codegen
    ├── devenv-direnv/      # devenv.nix theo stack, services, direnv
    └── zed-power-user/     # thao tác Zed: agent, tasks, multi-cursor, LSP, MCP
```

## Cách áp dụng (tự động)

Systemd user service **`zed-settings`** (định nghĩa trong `modules/packages.nix`)
chạy mỗi lần đăng nhập:

1. Merge `settings.json` vào `~/.config/zed/settings.json` — giá trị assets là chuẩn,
   **không đụng block `agent`** (quyền tool bạn đã duyệt vẫn giữ nguyên).
2. Thay `__HOME__` bằng đường dẫn nhà (dùng cho context server `fs`).
3. Copy đè `skills/` vào `~/.config/zed/skills/` (assets là nguồn chuẩn).

Áp dụng ngay không cần đăng nhập lại:

```bash
systemctl --user restart zed-settings
```

## Context servers (MCP)

| Server | Công dụng |
|---|---|
| `fs` | đọc/ghi file ngoài workspace (gốc `~`) |
| `context7` | tài liệu mới nhất (Laravel, Flutter, React, Node...) |
| `memory` | agent nhớ giữa các phiên |
| `fetch` | đọc web/URL |

Tất cả chạy qua `npx` (Node 24 đã cài). Kiểm tra trạng thái trong Agent panel.
Lưu ý: Zed không có cờ "disabled" cho context server trong settings — muốn tắt thì
xóa entry hoặc thêm chú thích (Zed chấp nhận JSONC).

## Skills

Zed tự phát hiện skill từ `~/.config/zed/skills/<tên>/SKILL.md` (global) và
`.zed/skills/` (theo dự án). Mỗi skill có frontmatter `name` + `description`;
agent kích hoạt theo mô tả khi cần. Skill theo dự án (`.zed/skills/`) nên commit
vào git của dự án để chia sẻ cho team.

## Sửa đổi

Sửa file trong `assets/zed/` rồi rebuild:

```bash
sudo nixos-rebuild switch --flake /etc/nixos#lg
# hoặc đồng bộ nhanh:
systemctl --user restart zed-settings
```

Mở lại Zed (hoặc phiên agent mới) để skill/context server có hiệu lực.
