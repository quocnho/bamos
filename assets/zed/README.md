# Zed editor — cấu hình chuyên nghiệp (assets)

Cấu hình chuẩn cho **Zed** (bản mới, binary `zeditor`) của **BamOS** — lưu trong repo
để tái lập mọi máy. Tham khảo [jellydn/zed-101-setup](https://github.com/jellydn/zed-101-setup)
(vim mode, which-key) và được thiết kế **cùng prefix phím với nvim BamOS** (`lua/bamos/`)
→ chuyển đổi giữa nvim ↔ Zed không phải học lại.

> Cấu hình thật nằm ở `~/.config/zed/` (do home-manager sinh/đồng bộ — KHÔNG sửa tay).

---

## 1. Cấu trúc & quy trình hoạt động

```
assets/zed/
├── README.md       ← file này
├── settings.json   # vim_mode + which_key, font/theme, MCP, nil LSP...
├── keymap.json     # vim keymap — cùng prefix <space> với nvim
├── sync.py         # script merge/copy (chạy bởi user service)
└── skills/         # Agent skills (chuẩn Agent Skills: SKILL.md)
```

**Cách config được áp dụng — qua HOME-MANAGER** (`home/dev.nix`):

1. Gói `zed-editor` cài ở cấp hệ thống (`modules/dev.nix`, `my.dev.enable`).
2. **User service `zed-settings`** (định nghĩa trong `home/dev.nix`) chạy mỗi lần đăng nhập:
    - **Merge** `settings.json` → `~/.config/zed/settings.json` — giá trị assets là chuẩn,
      **không đụng block `agent`** (quyền tool đã duyệt giữ nguyên); thay `__HOME__`
      (context server `fs`).
    - **Ghi đè** `keymap.json` (declarative — sửa trong assets nếu muốn thêm phím riêng).
    - **Copy đè** `skills/` (assets là nguồn chuẩn).
3. Zed tự reload config khi file đổi — không cần mở lại nếu chỉ đổi keymap/settings.

**Áp dụng sau khi sửa file trong `assets/zed/`:**

```bash
bam switch                    # cách chuẩn (rebuild home-manager)
# hoặc đồng bộ nhanh không cần rebuild:
systemctl --user restart zed-settings
```

---

## 2. Cài đặt & quy trình nạp

- Vim mode bật qua `"vim_mode": true` + `base_keymap: VSCode` trong settings.
- **Which-key bật sẵn** (`which_key.enabled`): gõ `<space>` → chờ ~400ms → hiện bảng
  nhóm phím (delay đặt trong settings, gần `timeoutlen` của nvim).
- Mỗi binding trong `keymap.json` có chú thích nvim tương ứng để dễ đối chiếu.
- Zed dùng chung **LSP qua PATH** như nvim. Các server dưới đây được ghim **đường dẫn
  tuyệt đối** trong `settings.json` (ổn định kể cả khi PATH bị tối giản):
  `nil` (Nix), `typescript-language-server`, `vue-language-server` (Volar).
- **Lưu ý quan trọng:** `typescript-language-server` và `vue-language-server` **bắt buộc**
  có tham số `--stdio`. Khi tự khai báo `lsp.<server>.binary` trong settings, Zed KHÔNG
  tự thêm tham số mặc định của adapter — thiếu `--stdio` sẽ lỗi ngay khi khởi động:
  `error: required option '--stdio' not specified`. Vì vậy luôn khai báo đủ:

  ```json
  "binary": { "path": "/run/current-system/sw/bin/typescript-language-server", "arguments": ["--stdio"] }
  ```

  (Vue: Volar thiếu `--stdio` cũng báo `Connection input stream is not set`.)

---

## 3. Keymap — nhanh (nhóm phím giống nvim)

> Prefix chính là **`<space>`**; phím `,` (leader nvim) trong Zed không dùng làm prefix
> (Zed xử lý `,` như phím thường) — lưu ý khi so sánh với nvim.

### 3.1 Tìm kiếm — `space f` (nvim: fzf-lua)

| Phím                      | Hành động                        |
| ------------------------- | -------------------------------- |
| `space f f`               | Tìm file                         |
| `space f g`               | Tìm trong toàn dự án (live grep) |
| `space f r` / `space f p` | File/project gần đây             |
| `space f n`               | File mới                         |
| `space space`             | Mở lại file finder               |

### 3.2 Git — `space g` (nvim: `<space>g*` + gitsigns)

| Phím          | Hành động                   |
| ------------- | --------------------------- |
| `space g s`   | Git panel (status)          |
| `space g d`   | Diff                        |
| `space g b`   | Bật/tắt inline blame        |
| `space g h d` | Bật/tắt diff hunk đang chọn |
| `]h` / `[h`   | Hunk kế / trước             |

### 3.3 LSP & code — `space c` / `g*` (nvim: lsp.lua)

| Phím                            | Hành động                         |
| ------------------------------- | --------------------------------- |
| `space c a` / `space .`         | Code actions                      |
| `space c r`                     | Rename                            |
| `space c f`                     | Format file                       |
| `g d` / `g D`                   | Go to definition (split)          |
| `g i` / `g I`                   | Implementation (split)            |
| `g t` / `g T`                   | Type definition (split)           |
| `g r`                           | References                        |
| `]d`/`[d`, `]e`/`[e`, `]w`/`[w` | Nhảy diagnostic / error / warning |

### 3.4 Terminal, buffer, window

| Phím                           | Hành động             | Ghi chú (nvim)           |
| ------------------------------ | --------------------- | ------------------------ |
| `space t t` / `ctrl-\`         | Bật/tắt terminal      | `<space>tt` / `<C-/>`    |
| `space t i`                    | Inlay hints           | `:LspInlayHints`         |
| `shift-h`/`shift-l`, `]b`/`[b` | Buffer kế/trước       | `<Tab>/<S-Tab>`, `gb/gB` |
| `space b b`                    | Quay lại buffer trước |                          |
| `space b d` / `ctrl-q`         | Đóng buffer           | `\db`                    |
| `space b o`                    | Đóng buffer khác      | `\dB`                    |
| `space w w`                    | Pane trước            |                          |
| `space w -` / `space w \|`     | Chia ngang / dọc      |                          |
| `space w d`                    | Đóng pane             |                          |
| `ctrl-h/j/k/l`                 | Đổi pane              | `<c-w>` + mũi tên        |
| `ctrl-shift-h/j/k/l`           | Resize pane           |                          |

### 3.5 Explorer, outline & hơn nữa

| Phím                      | Hành động                  | nvim tương ứng          |
| ------------------------- | -------------------------- | ----------------------- |
| `space s` / `space e`     | Reveal trong project panel | oil `<space>s/<space>e` |
| `space o`                 | Outline symbol             | aerial `<space>o`       |
| `space x x`               | Panel diagnostics          | `]d`/`<space>q*`        |
| `space c z`               | Centered layout (zen)      | no-neck-pain            |
| `space m p` / `space m P` | Preview markdown (cạnh)    | render-markdown         |
| `space q q`               | Đóng cửa sổ                | `,Q`                    |
| `g c` (visual)            | Comment                    | `gc`                    |
| `space a *`               | AI agent / inline assist   | (Zed dành riêng cho AI) |

### 3.6 Di chuyển & thoát insert

| Phím                          | Hành động                                        |
| ----------------------------- | ------------------------------------------------ |
| `jk` (insert)                 | Thoát insert (như nvim)                          |
| `s` / `S`                     | **Sneak** 2 ký tự tới/lùi (tương đương hop.nvim) |
| `alt-j` / `alt-k`             | Di chuyển dòng xuống / lên                       |
| `ctrl-s`                      | Lưu                                              |
| `ctrl-w h/j/k/l` (trong Dock) | Điều hướng pane                                  |

---

## 4. Settings đáng chú ý

| Mục                     | Giá trị                            | Lý do                              |
| ----------------------- | ---------------------------------- | ---------------------------------- |
| `vim_mode`              | `true`                             | soạn thảo kiểu vim                 |
| `which_key`             | `enabled, delay_ms: 400`           | hiện nhóm phím như nvim            |
| `relative_line_numbers` | `enabled`                          | như nvim                           |
| `scroll margins`        | 5 / 8                              | như nvim `scrolloff/sidescrolloff` |
| `git.inline_blame`      | `false`                            | bật bằng `space g b`               |
| `format_on_save`        | `on` · `autosave: on_focus_change` | soạn thảo tự động                  |
| `file_scan_exclusions`  | `.git`, `node_modules`, `result`…  | khớp nvim `wildignore`             |

---

## 5. Context servers (MCP)

| Server     | Công dụng                                            |
| ---------- | ---------------------------------------------------- |
| `fs`       | đọc/ghi file ngoài workspace (gốc `~`)               |
| `context7` | tài liệu mới nhất (Laravel, Flutter, React, Node...) |
| `memory`   | agent nhớ giữa các phiên                             |
| `fetch`    | đọc web/URL                                          |

Chạy qua `npx` (Node đã cài máy dev). Zed không có cờ tắt context server trong
settings — muốn tắt thì xóa entry hoặc chú thích (Zed chấp nhận JSONC).

---

## 6. Skills

Zed tự phát hiện skill từ `~/.config/zed/skills/<tên>/SKILL.md` (global) và
`.zed/skills/` (theo dự án). Skill theo dự án nên commit vào git của dự án để
chia sẻ cho team. Mỗi skill có frontmatter `name` + `description`.

---

## 7. Tùy biến & troubleshooting

- **Sửa config**: chỉ sửa file trong `assets/zed/` rồi `bam switch`
  (hoặc `systemctl --user restart zed-settings`) — không sửa tay `~/.config/zed`
  (sẽ bị ghi đè).
- **Thêm phím riêng**: thêm binding vào `keymap.json` (đúng context; tránh map
  phím đơn + phím con cùng prefix gây delay — xem chú thích trong file).
- **Xem phím đang dùng**: trong Zed mở Command Palette (`ctrl-shift-p`) → _Open Keymap_
  hoặc _vim: Which Key_ khi gõ `<space>`.
- **Agent bị reset?**: service KHÔNG đè block `agent` — nếu vô tình bị mất, kiểm tra
  `~/.config/zed/settings.json` có block `agent` không; Zed sẽ tự tạo lại bản mặc định.
- **Action báo lỗi khi gõ** (bản Zed cũ thiếu action mới): bỏ binding tương ứng
  trong `keymap.json` hoặc nâng cấp `zeditor`.
