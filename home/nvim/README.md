# Neovim BamOS — cấu hình hiện đại trên NixOS

Cấu hình Neovim **0.12+** dành cho developer trên **NixOS + home-manager** — kiến trúc
module theo phong cách [ray-x/nvim](https://github.com/ray-x/nvim) (nhẹ, theo domain)
và look [LazyVim](https://www.lazyvim.org/) (dashboard + which-key + bufferline), tham
khảo thêm [jellydn/lazy-nvim-ide](https://github.com/jellydn/lazy-nvim-ide) và
[jellydn/tiny-nvim](https://github.com/jellydn/tiny-nvim).

> Vị trí: `home/nvim/` trong repo BamOS (`/etc/nixos`). Bản cài trên máy nằm ở
> `~/.config/nvim` (do home-manager sinh).

---

## 1. Cách "vận hành" (cách config được cài & nạp)

```
home/dev.nix  ── programs.neovim ──────────────────────────────┐
   • plugins  = vimPlugins (Nix) — KHÔNG lazy.nvim            │
   • initLua  = 'require("bamos")'  → init.lua do HM sinh     ├─► ~/.config/nvim/
   • extraPackages = LSP/formatter/tools (PATH của nvim)      │
   • home.file = từng file dưới home/nvim/ → symlink vào       │
                ~/.config/nvim/...                            │
home/nvim/  ── thư mục config thật (file này) ────────────────┘
```

**Luồng nạp lúc mở nvim** (xem `lua/bamos/init.lua`):

1. `vim.loader.enable()` → bytecode cache nhanh.
2. `globals` (leader `,`, tắt provider/builtin thừa) → `options` → `keymaps` → `autocmds`.
3. `ime` (fcitx5: tự tắt bộ gõ khi ra khỏi insert/command-line).
4. `plugins.icons` (mini.icons — nạp TRƯỚC bufferline/lualine/snacks vì chúng cần icon).
5. Lần lượt từng nhóm plugin: `which-key → bufferline → lualine → snacks → cmp →
treesitter → picker → explorer → git → editor → folding → statuscol → navigation
→ markdown → terminal → notes → todo → extras`.
6. `diagnostic` → `lsp` (server có executable trong PATH mới bật — xem §5) → `theme`.

**Nguyên tắc quan trọng**

- Plugin cài qua **Nix** (`pkgs.vimPlugins` trong `home/dev.nix`): offline, reproducible —
  "cài mới là chạy", không fetch từ GitHub lúc runtime.
- Grammar **treesitter** cài qua `nvim-treesitter.withAllGrammars` (không cần compiler).
- **LSP/formatter** là binary Ngoài nvim: cài qua `extraPackages` hoặc do **devenv shell**
  cung cấp (sau `direnv allow`) → nvim tự bật theo PATH, không sửa config theo dự án.
- Nếu sửa config: chạy `bam switch` (hoặc `nixos-rebuild switch --flake /etc/nixos#lg`).

---

## 2. Cây thư mục

```
home/nvim/
├── README.md                      ← file này
├── lua/bamos/                     # CORE (không/ít phụ thuộc plugin)
│   ├── init.lua                   #   entry: thứ tự nạp
│   ├── {globals,options,keymaps,autocmds,ime,diagnostic,lsp,theme,utils}.lua
│   └── plugins/                   # MỘT FILE MỘT NHÓM/PLUGIN (chuẩn LazyVim)
│       ├── icons.lua              #   mini.icons (mock nvim-web-devicons)
│       ├── which-key.lua          #   menu phím (v3) + khai báo group
│       ├── bufferline.lua         #   tab buffer kiểu IDE
│       ├── lualine.lua            #   statusline
│       ├── snacks.lua             #   dashboard + notifier + indent + lazygit…
│       ├── cmp.lua                #   completion blink.cmp
│       ├── treesitter.lua         #   highlight/indent + textobjects/swap/move
│       ├── picker.lua             #   fzf-lua (tìm kiếm chính)
│       ├── explorer.lua           #   oil.nvim (filesystem như buffer)
│       ├── git.lua                #   gitsigns + fugitive (+ lazygit qua snacks)
│       ├── editor.lua             #   autopairs, sandwich, commentary, yanky…
│       ├── folding.lua            #   nvim-ufo (fold LSP/treesitter)
│       ├── statuscol.lua          #   cột số/sign gọn, click được
│       ├── navigation.lua         #   aerial (outline), hop, hlslens
│       ├── markdown.lua           #   render-markdown
│       ├── terminal.lua           #   tiny-term (float/split, <C-/>)
│       ├── notes.lua              #   my-note (ghi chú nhanh ,n)
│       ├── todo.lua               #   todo-comments (<space>T)
│       └── extras.lua             #   colorizer, illuminate, lightbulb, fidget, bqf…
├── after/lsp/<server>.lua         # config RIÊNG từng LSP (return table — chuẩn 0.11+)
└── after/ftplugin/<filetype>.lua  # cấu hình theo loại file (python, markdown, go…)
```

---

## 3. Khởi động — Dashboard & Theme

- Mở `nvim` **không kèm file** → **dashboard** (snacks, kiểu LazyVim/Nv) hiện ra;
  mở **tab mới không kèm file** (`:tabnew`) dashboard cũng tự hiện (theo Nv).
- Trên dashboard, gõ **1 phím** để vào việc (dưới cùng là danh sách **file gần đây**,
  mỗi dòng gán ký tự — gõ ký tự là mở file ngay):

| Phím | Hành động                      |
| ---- | ------------------------------ |
| `f`  | Tìm file (fzf-lua)             |
| `g`  | Tìm trong nội dung (live grep) |
| `r`  | File gần đây                   |
| `b`  | Danh sách buffer               |
| `n`  | File mới                       |
| `c`  | Mở thư mục config nvim         |
| `q`  | Thoát                          |

- **Theme**: mặc định `tokyonight`. Đổi nhanh: `,ut` (tới) / `,uT` (lùi) hoặc
  `:BamosTheme <tên>`. Danh sách: `tokyonight`, `catppuccin`, `gruvbox-material`,
  `kanagawa-dragon`, `carbonfox` (xem `lua/bamos/theme.lua`).
- **Bộ gõ tiếng Việt (fcitx5-unikey)**: tự TẮT khi mở nvim, rời insert (`Esc`/`<C-c>`),
  vào command-line, hoặc rời terminal — khi cần gõ tiếng Việt tự bật thủ công trong
  insert (xem `lua/bamos/ime.lua`).

---

## 4. Keymap — nhanh

> Có **2 leader**: phím `,` (cá nhân) và `<space>` (nhóm chức năng — giống LazyVim).
> which-key tự hiện bảng phím sau ~500ms khi bạn gõ `,` hoặc `<space>`. Chữ viết hoa
> = phím Shift (vd `,Q` = `,`+`Shift+q`).

### 4.1 Phím chung (core — `lua/bamos/keymaps.lua`)

| Phím                    | Hành động                                 |
| ----------------------- | ----------------------------------------- |
| `;` (n/x)               | vào command mode (thay `:`)               |
| `jk` (i)                | thoát insert                              |
| `,w`                    | lưu buffer                                |
| `,q`                    | lưu + thoát · `,Q` thoát tất cả           |
| `,p` / `,P`             | dán xuống/trên dòng hiện tại              |
| `,v`                    | chọn lại vùng vừa dán                     |
| `,y`                    | yank cả buffer                            |
| `,Y` (n/x)              | copy ra ngoài qua OSC52 (tmux/ssh)        |
| `,cd`                   | đổi cwd theo file hiện tại                |
| `,cl`                   | bật/tắt highlight cột                     |
| `,<space>`              | xoá khoảng trắng cuối dòng                |
| `,ut` / `,uT`           | theme tới / lùi                           |
| `,n`                    | ghi chú nhanh (MyNote — theo project git) |
| `Q`                     | lặp lại macro vừa ghi (thanh ghi `q`)     |
| `gb` / `gB`             | buffer kế / trước                         |
| `<Tab>` / `<S-Tab>`     | buffer kế / trước (bufferline)            |
| `\db` / `\dB`           | xoá buffer hiện tại / các buffer khác     |
| `\dt` / `\dT`           | đóng tab / các tab khác                   |
| `\x`                    | đóng quickfix + location list             |
| `<A-j>` / `<A-k>` (n/x) | di chuyển dòng/khối lên xuống             |
| `J`                     | nối dòng, giữ con trỏ                     |
| `<left/right/up/down>`  | chuyển cửa sổ hướng đó                    |
| `<F11>`                 | bật/tắt spellcheck                        |
| `<C-a>` / `<C-e>` (c)   | Home / End trong command-line             |

Lưu ý: giữ nguyên thao tác insert chuẩn (viết code nhanh): `<C-u>` xoá về đầu dòng,
`<C-t>`/`<C-d>` thụt lề, `<C-e>` chèn ký tự dòng trên, `<C-a>` lặp chèn, `<C-r>` paste
register, `c`/`C`/`cc` xoá KHÔNG bẩn register (đã remap).

### 4.2 Nhóm `<space>`

| Phím                                                   | Hành động                                |
| ------------------------------------------------------ | ---------------------------------------- |
| **`<space>f` = tìm kiếm (fzf-lua)**                    |                                          |
| `space ff`                                             | tìm file                                 |
| `space fg`                                             | live grep toàn dự án                     |
| `space fb`                                             | danh sách buffer                         |
| `space fr`                                             | file gần đây                             |
| `space fh`                                             | help tags                                |
| `space fq`                                             | quickfix list                            |
| `space f;`                                             | danh sách lệnh                           |
| `space fp`                                             | file trong git                           |
| `space fc`                                             | git commits                              |
| **`<space>g` = git**                                   |                                          |
| `space gv`                                             | git status (fugitive `:Git`)             |
| `space gd`                                             | git diff (split)                         |
| `space gl`                                             | git log                                  |
| `space gb`                                             | git blame                                |
| `space gy` (n/x)                                       | mở file/dòng trên GitHub                 |
| `space gg`                                             | **lazygit** (UI git đầy đủ)              |
| `]h` / `[h`                                            | hunk kế / trước (gitsigns)               |
| `,gp` / `,gr` / `,gs`                                  | preview / reset / stage hunk             |
| **`<space>c` / `<space>r` = LSP/code** (buffer có LSP) |                                          |
| `space ca`                                             | code action                              |
| `space rn`                                             | rename                                   |
| `gd` / `gD`                                            | go to definition / split                 |
| `K`                                                    | hover (tài liệu)                         |
| `<C-]>`                                                | definition nhanh                         |
| `<C-k>`                                                | signature help                           |
| `space wa/wr/wl`                                       | workspace folder thêm/xoá/list           |
| **`<space>q` = diagnostics**                           |                                          |
| `space qw` / `space qb`                                | diagnostic window/buffer → quickfix      |
| `]d` / `[d`                                            | diagnostic kế / trước (kèm float)        |
| **`<space>t` = terminal**                              |                                          |
| `space tt`                                             | toggle terminal (bottom split)           |
| `space tf`                                             | terminal nổi (float)                     |
| `<C-/>`                                                | toggle nhanh (gõ `2<C-/>` = terminal #2) |
| **`<space>z` = fold (ufo)**                            |                                          |
| `space zR` / `space zM`                                | mở / đóng MỌI fold                       |
| `space zr` / `space zm`                                | mở / đóng fold tại con trỏ               |
| **`<space>h` = hop (nhảy nhanh)**                      |                                          |
| `space hh` / `hw`                                      | nhảy theo 2 ký tự / theo word            |
| `space hl` / `hp`                                      | nhảy theo dòng / pattern                 |
| **Explorer & hơn nữa**                                 |                                          |
| `space s`                                              | oil — mở thư mục cha (như buffer)        |
| `space e`                                              | oil — cửa sổ nổi                         |
| `space o`                                              | outline symbol (aerial, sidebar phải)    |
| `space y`                                              | lịch sử yank (yanky)                     |
| `space T`                                              | tìm TODO/FIXME (todo-comments qua fzf)   |

### 4.3 Text objects & di chuyển theo cú pháp (treesitter-textobjects)

| Phím                                                             | Hành động                                                                                                                   |
| ---------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| `af`/`if`, `ac`/`ic`, `aa`/`ia`, `ab`/`ib`, `al`/`il`, `at`/`it` | chọn function/class/parameter/block/loop/conditional (outer/inner) — dùng trong **visual & operator** (vd `daf` xoá cả hàm) |
| `]f`/`[f`, `]F`/`[F`                                             | function kế/trước (đầu / cuối)                                                                                              |
| `]c`/`[c`, `]C`/`[C`                                             | class kế/trước (đầu / cuối)                                                                                                 |
| `,a` / `,A`                                                      | swap tham số kế / trước                                                                                                     |
| `sa`/`sd`/`sr`                                                   | vim-sandwich: bọc / xoá / thay cặp (vd `saiw"` bọc từ bằng `"`)                                                             |
| `gc`/`gcc`                                                       | comment dòng/đoạn (vim-commentary)                                                                                          |

### 4.4 Theo loại file (`after/ftplugin/`)

- **Python**: `<F9>` chạy file (`uv run` nếu project uv) · `<space>f` format bằng black.
- **Markdown**: `:AddRef <label> <url>` thêm reference link cuối file.
- **Help**: `q` đóng cửa sổ help.
- Go/JSON/YAML/Vim/Tex…: xem file tương ứng trong `after/ftplugin/`.

### 4.5 Command hữu ích

| Lệnh                                      | Công dụng                    |
| ----------------------------------------- | ---------------------------- |
| `:LspInfo` / `:LspLog` / `:LspRestart`    | kiểm tra / log / restart LSP |
| `:LspInlayHints enable                    | disable`                     | bật/tắt inlay hints |
| `:BamosTheme <tên>`                       | đổi theme (có gợi ý)         |
| `:MyNote`                                 | mở ghi chú nhanh (như `,n`)  |
| `:TinyTerm [cmd]` · `:TinyTermOpen <cmd>` | terminal shell / chạy lệnh   |
| `:TodoQuickFix` / `:TodoLocList`          | todo → quickfix / loclist    |
| `:StripTrailingWhitespace`                | xoá khoảng trắng cuối        |
| `:FzfLua …`                               | mọi picker của fzf-lua       |

---

## 5. LSP hoạt động thế nào

- Nvim ≥0.11 API: `vim.lsp.enable(<tên>)` (file `lua/bamos/lsp.lua`) — server nào có
  **executable trong PATH** thì tự bật; server bắt buộc (khai trong `extraPackages`)
  thiếu sẽ cảnh báo bằng notifier.
- Config riêng từng server nằm ở `after/lsp/<tên>.lua` (return table).
- Bộ mặc định: `nil` (Nix), `lua_ls`, `pyright`, `ts_ls`, `bashls`, `marksman`,
  `yamlls`, `html`/`cssls`/`jsonls`, `taplo`. Server tùy dự án (devenv): `ruff`,
  `gopls`, `clangd`, `typos_lsp`…
- **Format khi lưu** tự động qua LSP cho: python, lua, nix, ts/js/tsx/jsx, go, rust,
  c/cpp, json, yaml, markdown, sh (sửa danh sách ở đầu `lua/bamos/autocmds.lua`).
- Diagnostics: sign + float khi đứng yên trên lỗi (`CursorHold`), không virtual text.

---

## 6. Tùy biến (developer guide)

**Thêm plugin** — ví dụ `vim-illuminate`-style hoặc plugin mới:

1. `home/dev.nix` → khai trong `programs.neovim.plugins` (tên `pkgs.vimPlugins.<name>`).
   Plugin chưa có trong nixpkgs: thêm vào `let jellydnPlugins` kiểu `buildVimPlugin`
    - `fetchFromGitHub` (pin rev/hash) — đã có ví dụ my-note & tiny-term.
2. Tạo `lua/bamos/plugins/<nhóm>.lua` (hoặc file riêng) để setup + keymap.
3. Thêm tên module vào danh sách nạp trong `lua/bamos/init.lua` **và** vào danh sách
   `home.file` trong `home/dev.nix` (mọi file phải khai ở đó thì mới được copy).
4. `bam switch` → mở nvim kiểm tra.

**Thêm LSP**: cài package vào `extraPackages` (home/dev.nix) + dòng
`{ <tên> = { exe = "binary", optional = true|false } }` trong `lua/bamos/lsp.lua`
(+ file `after/lsp/<tên>.lua` nếu cần cấu hình).

**Thêm theme**: cài plugin trong dev.nix + thêm hàm vào `themes`/`theme_config` trong
`lua/bamos/theme.lua`.

**Đổi phím**: tìm file theo mục §2; mọi keymap có `desc` → which-key tự cập nhật.
Tránh map phím đơn + map con cùng prefix (vd `<space>s` và `<space>sb`) vì gây delay.

---

## 7. Troubleshooting

| Vấn đề                                 | Cách xử lý                                                                                          |
| -------------------------------------- | --------------------------------------------------------------------------------------------------- |
| Lỗi khi khởi động sau khi sửa          | `nvim -V1` hoặc đọc dòng lỗi đầu tiên; kiểm tra lại §6 bước 1–3 (file khai thiếu trong `home.file`) |
| Plugins/grammar không tải              | `:checkhealth` (đặc biệt `nvim-treesitter`, `blink.cmp`, LSP)                                       |
| Cảnh báo "Executable … không tìm thấy" | cài server vào `extraPackages` hoặc `direnv allow` đúng project                                     |
| Thay đổi config chưa có hiệu lực       | chạy `bam switch` (config nằm trong Nix, không phải sửa tay ở `~/.config/nvim`)                     |
| Nâng cấp nvim bản mới, luac cache cũ   | `rm -rf ~/.cache/nvim/luac` rồi mở lại                                                              |
| Muốn xem phím đang map                 | gõ `<space>` hoặc `,` chờ which-key · `:nmap <prefix>` · `:Telescope keymaps` (nếu cài)             |
| Quên cú pháp fold/motion               | `:help ufo` · `:help nvim-treesitter-textobjects` · `:help hop`                                     |

---

## 8. Plugin chính & nguồn

| Plugin                                                                              | Công dụng                            | Config                   |
| ----------------------------------------------------------------------------------- | ------------------------------------ | ------------------------ |
| [snacks.nvim](https://github.com/folke/snacks.nvim)                                 | dashboard, notifier, indent, lazygit | `plugins/snacks.lua`     |
| [blink.cmp](https://github.com/saghen/blink.cmp)                                    | completion (LSP/snippet/path/buffer) | `plugins/cmp.lua`        |
| [fzf-lua](https://github.com/ibhagwan/fzf-lua)                                      | fuzzy finder chính                   | `plugins/picker.lua`     |
| [oil.nvim](https://github.com/stevearc/oil.nvim)                                    | explorer                             | `plugins/explorer.lua`   |
| [bufferline.nvim](https://github.com/akinsho/bufferline.nvim)                       | tab buffer                           | `plugins/bufferline.lua` |
| [which-key.nvim](https://github.com/folke/which-key.nvim)                           | menu phím                            | `plugins/which-key.lua`  |
| [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim)                         | dấu git + hunk                       | `plugins/git.lua`        |
| [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) + textobjects | cú pháp/textobjects                  | `plugins/treesitter.lua` |
| [aerial.nvim](https://github.com/stevearc/aerial.nvim)                              | outline                              | `plugins/navigation.lua` |
| [hop.nvim](https://github.com/smoka7/hop.nvim)                                      | nhảy nhanh                           | `plugins/navigation.lua` |
| [nvim-ufo](https://github.com/kevinhwang91/nvim-ufo)                                | fold                                 | `plugins/folding.lua`    |
| [tiny-term.nvim](https://github.com/jellydn/tiny-term.nvim)                         | terminal                             | `plugins/terminal.lua`   |
| [my-note.nvim](https://github.com/jellydn/my-note.nvim)                             | ghi chú nhanh                        | `plugins/notes.lua`      |
| [todo-comments.nvim](https://github.com/folke/todo-comments.nvim)                   | TODO/FIXME                           | `plugins/todo.lua`       |
| [yanky.nvim](https://github.com/gbprod/yanky.nvim)                                  | lịch sử yank                         | `plugins/editor.lua`     |
| [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim)                        | statusline                           | `plugins/lualine.lua`    |

Hầu hết plugin cài qua `pkgs.vimPlugins` (xem `home/dev.nix`); jellydn plugins chưa có
trong nixpkgs được pin rev/hash trong `let jellydnPlugins` ở đầu file đó.
