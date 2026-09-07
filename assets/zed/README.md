# Zed editor — Cấu hình chuyên nghiệp (assets)

Cấu hình chuẩn cho **Zed** (bản mới, binary `zeditor`) — lưu trong repo để tái lập.
Tham khảo [jellydn/zed-101-setup](https://github.com/jellydn/zed-101-setup) (vim mode,
which-key) + đồng bộ phím với **nvim BamOS** (`lua/bamos/`).

## Cấu trúc

```
assets/zed/
├── settings.json   # Font 17/18 (JetBrainsMono Nerd Font Mono), theme One Dark,
│                   #   vim_mode + which_key (như nvim), MCP context_servers, nil LSP...
├── keymap.json     # Vim keymap — CÙNG prefix <space> với nvim (f/g/c/t/w/z…),
│                   #   which-key hiện group; chú thích cặp nvim cạnh mỗi binding
└── skills/         # Agent skills (SKILL.md, chuẩn Agent Skills):
    ├── php-laravel/        # artisan, migration, Eloquent, queue, Pint, xdebug
    ├── php-codeigniter/    # spark, model, migration, Query Builder, validation
    ├── mysql-database/     # schema, index, EXPLAIN, transaction, backup
    ├── typescript-node-pwa/ # tsconfig, pnpm, ESM, vitest, manifest, service worker
    ├── flutter-dev/        # analyze/test/build, state management, codegen
    ├── devenv-direnv/      # devenv.nix theo stack, services, direnv
    └── zed-power-user/     # thao tác Zed: agent, tasks, multi-cursor, LSP, MCP
```

## Nhóm phím (khớp nvim — which-key hiện sau 400ms khi gõ `<space>`)

| Prefix                  | Ý nghĩa (giống nvim)                          |
| ----------------------- | --------------------------------------------- |
| `space f`               | tìm file / grep / recent / new file           |
| `space g`               | git: status, diff, blame, hunk                |
| `space c`               | LSP: code action, rename, format              |
| `space t`               | terminal, inlay hints                         |
| `space b`               | buffer/tab: close, close-others, prev         |
| `space w`               | pane: previous, split, close                  |
| `space q`               | thoát / đóng                                  |
| `space a`               | AI agent / inline assist                      |
| `space s`/`space e`     | explorer (reveal project panel)               |
| `space o`               | outline (như aerial)                          |
| `]d/[d` `]e/[e` `]w/[w` | di chuyển diagnostic/error/warning (như nvim) |
| `]h/[h`                 | git hunk (như gitsigns)                       |
| `jk`                    | thoát insert (như nvim)                       |
| `s`/`S`                 | sneak 2 ký tự (như hop.nvim)                  |

## Cách áp dụng (tự động)

Systemd user service **`zed-settings`** (định nghĩa trong `modules/dev.nix`) chạy mỗi
lần đăng nhập:

1. Merge `settings.json` vào `~/.config/zed/settings.json` — giá trị assets là chuẩn,
   **không đụng block `agent`** (quyền tool bạn đã duyệt vẫn giữ nguyên).
2. Ghi đè `keymap.json` (declarative — sửa trong assets nếu muốn thêm phím riêng).
3. Thay `__HOME__` bằng đường dẫn nhà (dùng cho context server `fs`).
4. Copy đè `skills/` vào `~/.config/zed/skills/` (assets là nguồn chuẩn).

Áp dụng ngay không cần đăng nhập lại (Zed tự reload config khi file đổi):

```bash
systemctl --user restart zed-settings
```

## Context servers (MCP)

| Server     | Công dụng                                            |
| ---------- | ---------------------------------------------------- |
| `fs`       | đọc/ghi file ngoài workspace (gốc `~`)               |
| `context7` | tài liệu mới nhất (Laravel, Flutter, React, Node...) |
| `memory`   | agent nhớ giữa các phiên                             |
| `fetch`    | đọc web/URL                                          |

Tất cả chạy qua `npx` (Node đã cài trên máy dev). Kiểm tra trạng thái trong Agent panel.
Lưu ý: Zed không có cờ "disabled" cho context server trong settings — muốn tắt thì
xóa entry hoặc thêm chú thích (Zed chấp nhận JSONC).

## Skills

Zed tự phát hiện skill từ `~/.config/zed/skills/<tên>/SKILL.md` (global) và
`.zed/skills/` (theo dự án). Mỗi skill có frontmatter `name` + `description`;
agent kích hoạt theo mô tả khi cần. Skill theo dự án (`.zed/skills/`) nên commit
vào git của dự án để chia sẻ cho team.

## Sửa đổi

Sửa file trong `assets/zed/` rồi rebuild (hoặc đồng bộ nhanh bằng lệnh trên):

```bash
sudo nixos-rebuild switch --flake /etc/nixos#lg
# hoặc đồng bộ nhanh:
systemctl --user restart zed-settings
```

Mở lại Zed (hoặc phiên agent mới) để skill/context server có hiệu lực.
