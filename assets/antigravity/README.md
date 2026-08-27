# Antigravity — Cấu hình chuyên nghiệp (assets)

Cấu hình chuẩn cho **Antigravity IDE** (VS Code-based) + **Antigravity CLI** (`agy`)
— lưu trong repo để tái lập sau mỗi lần cài đặt mới.

## Cấu trúc

```
assets/antigravity/
├── settings.json        # IDE settings: font 17 (JetBrainsMono Nerd Font), theme Catppuccin,
│                        #   formatter theo ngôn ngữ, direnv, terminal zsh...
├── mcp_config.json      # MCP servers (fs, context7, memory, fetch, mysql)
└── skills/              # Skills cho agent (đọc/ghi từng thư mục con):
    ├── php-laravel/     #   artisan, migration, Eloquent, queue, testing, Pint, xdebug
    ├── php-codeigniter/ #   spark, model, migration, validation, Query Builder
    ├── mysql-database/  #   schema, index, EXPLAIN, transaction, backup
    ├── typescript-node-pwa/ # tsconfig, pnpm, ESM, vitest, manifest, service worker
    ├── flutter-dev/     #   flutter analyze/test/build, state management, codegen
    └── devenv-direnv/   #   devenv.nix theo stack, services, direnv allow/reload
```

## Cách áp dụng (tự động)

Systemd user service **`antigravity-settings`** (định nghĩa trong
`modules/packages.nix`) chạy mỗi lần đăng nhập:

1. **settings.json** → merge vào `~/.config/Antigravity IDE/User/settings.json`
   (giá trị trong assets là chuẩn, ghi đè).
2. **mcp_config.json** → merge vào `~/.gemini/config/mcp_config.json`:
   - Thêm server chưa có;
   - Đồng bộ lại server đang giống template (vd: thay `__HOME__`);
   - **Giữ nguyên** server đã được bạn sửa tay (không đè).
3. **skills/** → copy đè vào `~/.gemini/config/skills/` (assets là nguồn chuẩn).

Muốn áp dụng ngay không cần đăng nhập lại:

```bash
systemctl --user restart antigravity-settings
```

## Sửa đổi

Sửa file trong `assets/antigravity/` rồi rebuild:

```bash
sudo nixos-rebuild switch --flake /etc/nixos#lg
# hoặc chỉ đồng bộ nhanh:
systemctl --user restart antigravity-settings
```

## MySQL MCP (tắt mặc định — bảo mật)

`mysql` server được để `disabled: true` vì cần mật khẩu DB của bạn:

```bash
# 1. Điền MYSQL_PASSWORD (+ MYSQL_DB nếu cần) vào ~/.gemini/config/mcp_config.json
# 2. Bật:
agy mcp enable mysql
agy mcp list
```

Hoặc mở IDE → **More Options (…) → MCP Servers** → bật + sửa env.

## Extensions cần thiết cho stack (cài 1 lần, cần mạng)

IDE đã cài sẵn các extension sau — nếu cài máy mới, chạy lại:

```bash
for ext in \
  bmewburn.vscode-intelephense-client \
  xdebug.php-debug \
  onecentlin.laravel-blade \
  shufo.vscode-blade-formatter \
  amiralizadeh9480.laravel-extra-intellisense \
  cweijan.vscode-database-client2 \
  mtxr.sqltools \
  dbaeumer.vscode-eslint \
  esbenp.prettier-vscode \
  vue.volar \
  bradlc.vscode-tailwindcss \
  Dart-Code.dart-code \
  Dart-Code.flutter \
  jnoortheen.nix-ide \
  mkhl.direnv \
  eamodio.gitlens \
  pkief.material-icon-theme \
  catppuccin.catppuccin-vsc \
  bierner.markdown-mermaid \
  usernamehw.errorlens \
  tamasfe.even-better-toml \
  ms-python.python \
  golang.go \
  shopify.ruby-lsp \
; do antigravity-ide --install-extension "$ext"; done
```

Ghi chú:
- **Lighthouse PWA** không còn trên marketplace — dùng `npx lighthouse <url>` (đã có nodejs) hoặc Chrome DevTools.
- Extension được lưu ở `~/.antigravity-ide/extensions/`; `ms-python.python`,
  `ms-toolsai.jupyter*`, `googlecloudtools.datacloud`… do IDE tự cài khi cần.

## CLI (`agy`)

- `agy mcp list` / `agy mcp add <name> <cmd> [args]` / `agy mcp enable <name>`
- `agy plugin import --from claude` — kéo plugin Claude Code về nếu có
- `agy models` — xem model (cần đăng nhập)
- Alias shell: `antigravity` = `antigravity-ide`, `agy` = `agy` (modules/shell.nix)
