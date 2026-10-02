# BamOS Codebase Architecture & Context Map

> **Dành cho AI Assistants (Gemini, Claude, GPT, Antigravity, Cursor, Zed):**
> Đọc tài liệu này trước để định tuyến trực tiếp đến đúng file cần sửa. Không quét/grep diện rộng trên toàn bộ repo.
> Toàn bộ các file cấu hình Nix đều được chuẩn hóa theo mô hình **Atomic Micro-Modules (< 80 dòng/file)**.

## 1. Directory Structure Map

```text
/etc/nixos/
├── flake.nix                         # Root Flake: hosts (lg, installer), packages (bam, iso), modules export
├── configuration.nix                 # Fallback entrypoint cho legacy nixos-rebuild
├── hosts/                            # Cấu hình cụ thể từng máy (Hardware + Custom module flags)
│   ├── lg/                           # Host chính (LG laptop)
│   │   ├── default.nix               # Cấu hình flags (my.*.enable), journald, stateVersion (< 40 dòng)
│   │   └── user.nix                  # Khai báo user quocnho, shell, groups (< 30 dòng)
│   ├── lg.nix                        # Shim trỏ vào hosts/lg/default.nix
│   └── installer.nix                 # Cấu hình build Live ISO Calamares
├── profiles/                         # Profiles (common, desktop, standard, dev, studio, gaming, installer)
│   ├── installer/                    # Profile cài đặt LiveCD
│   │   ├── default.nix               # Aggregator installer profile (< 20 dòng)
│   │   ├── calamares.nix             # Calamares overlay + DPI autostart patch (< 70 dòng)
│   │   └── iso.nix                   # ISO image build settings (< 25 dòng)
│   └── installer.nix                 # Shim trỏ vào profiles/installer/default.nix
├── modules/                          # System-level NixOS modules (bật tắt qua `my.<module>.enable`)
│   ├── default.nix                   # Module aggregator
│   ├── boot/                         # Bootloader & kernel
│   │   ├── default.nix               # Systemd-boot, kernel selection (< 45 dòng)
│   │   └── plymouth.nix              # Splash screen & quiet kernel params (< 25 dòng)
│   ├── boot.nix                      # Shim trỏ vào modules/boot/default.nix
│   ├── gpu/                          # NVIDIA PRIME / Intel graphics
│   │   ├── default.nix               # Nvidia PRIME offload & RTD3 power management (< 50 dòng)
│   │   └── intel.nix                 # Intel iGPU, VAAPI, i915 initrd (< 25 dòng)
│   ├── gpu.nix                       # Shim trỏ vào modules/gpu/default.nix
│   ├── power/                        # TLP & nguồn điện
│   │   ├── default.nix               # Suspend S3, thermald, lid switch (< 35 dòng)
│   │   ├── tlp.nix                   # TLP battery & CPU policy (< 30 dòng)
│   │   └── rtc-wakeup.nix            # RTC sync timer & USB keyboard wakeup (< 35 dòng)
│   ├── power.nix                     # Shim trỏ vào modules/power/default.nix
│   ├── audio/                        # PipeWire / WirePlumber
│   │   ├── default.nix               # PipeWire stack aggregator (< 40 dòng)
│   │   ├── low-latency.nix           # Quantum 256, 48kHz & camera disable (< 30 dòng)
│   │   ├── noise-suppression.nix     # Rnnoise noise-canceling mic (< 55 dòng)
│   │   └── codec-heal.nix            # Auto heal analog codec service (< 40 dòng)
│   ├── audio.nix                     # Shim trỏ vào modules/audio/default.nix
│   ├── gnome/                        # GNOME Desktop, Dconf, GDM, Extensions
│   │   ├── default.nix               # GNOME & GDM entrypoint (< 45 dòng)
│   │   ├── extensions.nix            # Exclude packages & extensions (< 35 dòng)
│   │   ├── dconf.nix                 # Interface, fonts, dock, mutter settings (< 65 dòng)
│   │   ├── keybindings.nix           # Custom workspace/window shortcuts (< 25 dòng)
│   │   └── store.nix                 # GNOME software & Flatpak integration (< 40 dòng)
│   ├── gnome.nix                     # Shim trỏ vào modules/gnome/default.nix
│   ├── studio/                       # OBS, NVENC/VAAPI, video/audio production
│   │   ├── default.nix               # Studio aggregator & fonts (< 25 dòng)
│   │   ├── options.nix               # Studio option definitions (< 55 dòng)
│   │   ├── obs.nix                   # OBS Studio + NVENC wrapper + plugins (< 40 dòng)
│   │   ├── production.nix            # Multimedia apps & video tools (< 50 dòng)
│   │   └── fonts.nix                 # Creator fonts list (< 30 dòng)
│   ├── studio.nix                    # Shim trỏ vào modules/studio/default.nix
│   ├── gaming/                       # Steam, GameMode, MangoHud, sysctl gaming
│   │   ├── default.nix               # Gaming options & aggregator (< 45 dòng)
│   │   ├── steam.nix                 # Steam client & firewall (< 25 dòng)
│   │   └── optimizations.nix         # GameMode, MangoHud, sysctl tweaks (< 40 dòng)
│   ├── gaming.nix                    # Shim trỏ vào modules/gaming/default.nix
│   ├── assets/                       # Wallpapers, fonts system-wide
│   │   ├── default.nix               # Assets aggregator (< 35 dòng)
│   │   ├── fonts.nix                 # System fonts & fontconfig ClearType (< 55 dòng)
│   │   └── wallpapers.nix            # Wallpapers & GDM background (< 25 dòng)
│   ├── assets.nix                    # Shim trỏ vào modules/assets/default.nix
│   ├── update/                       # Auto-update timer & services
│   │   ├── default.nix               # Update timer & option (< 35 dòng)
│   │   ├── services.nix              # Update systemd services (< 60 dòng)
│   │   ├── update.sh                 # Shell script thực thi cập nhật
│   │   └── update-notify-failure.sh  # Script gửi desktop notification lỗi
│   └── update.nix                    # Shim trỏ vào modules/update/default.nix
├── home/                             # User-level configurations (Home-Manager)
│   ├── default.nix                   # User base aggregator
│   ├── lg.nix                        # User specific cho máy lg
│   ├── programs/                     # Shell, CLI, Git
│   │   ├── shell/                    # Zsh, Starship, Fzf, Zoxide, Aliases
│   │   │   ├── default.nix           # Shell aggregator (< 20 dòng)
│   │   │   ├── zsh.nix               # Zsh history & keybindings (< 30 dòng)
│   │   │   ├── aliases.nix           # Shell aliases (< 45 dòng)
│   │   │   ├── starship.nix          # Starship prompt theme (< 50 dòng)
│   │   │   └── helpers.nix           # Fzf & Zoxide integration (< 30 dòng)
│   │   ├── shell.nix                 # Shim trỏ vào home/programs/shell/default.nix
│   │   ├── git.nix                   # Git, Delta pager, SSH config (< 50 dòng)
│   │   └── cli.nix                   # Tiện ích CLI: jq, yq, ripgrep, btop... (< 30 dòng)
│   └── dev/                          # Developer tools
│       ├── default.nix               # Dev module aggregator
│       ├── nvim/                     # Neovim configuration
│       │   ├── default.nix           # Neovim entrypoint (< 30 dòng)
│       │   ├── custom-plugins.nix    # Custom plugins build ngoài nixpkgs (< 30 dòng)
│       │   ├── plugins.nix           # Danh sách vimPlugins (< 75 dòng)
│       │   ├── extra-packages.nix    # LSP servers & formatters CLI (< 40 dòng)
│       │   └── links.nix             # Symlinks lua config sang ~/.config/nvim (< 78 dòng)
│       ├── nvim.nix                  # Shim trỏ vào home/dev/nvim/default.nix
│       ├── tmux.nix                  # Tmux + tmux plugins (< 30 dòng)
│       ├── zed.nix                   # Zed editor sync user service (< 30 dòng)
│       └── tools.nix                 # Direnv, gh, lazygit, dev cli packages (< 45 dòng)
└── pkgs/                             # Custom derivations viết riêng
    └── bam/                          # Bam CLI tool (`bam switch`, `bam update`, etc.)
```

### Subsystem Shorthand Prefixes (`?`, `@`, `/`)
AI Agent PHẢI tự động định tuyến toàn bộ thao tác context/file/command vào đúng thư mục con khi user mở đầu prompt bằng các tiền tố:
- `?os:` hoặc `@os:` (hoặc `?bamos:`, `@bamos:`) -> Trỏ vào [BamOS](file:///home/quocnho/Projects/Bam/BamOS)
- `?customizer:` hoặc `@customizer:` -> Trỏ vào [BamApps/bam-customizer](file:///home/quocnho/Projects/Bam/BamApps/bam-customizer)
- `?notes:` hoặc `@notes:` -> Trỏ vào [BamApps/bam-notes](file:///home/quocnho/Projects/Bam/BamApps/bam-notes)
- `?installer:` hoặc `@installer:` (hoặc `?iso:`) -> Trỏ vào [profiles/installer](file:///home/quocnho/Projects/Bam/BamOS/profiles/installer)
- `?nvim:` hoặc `@nvim:` -> Trỏ vào [home/dev/nvim](file:///home/quocnho/Projects/Bam/BamOS/home/dev/nvim)
- Khi nhận tiền tố, Agent luôn gắn tag `[Target: <subsystem>]` ở đầu câu trả lời và cô lập hoàn toàn thao tác vào subsystem đó.

## 2. Token Saving Guidelines for AI
- **Targeted Reading**: Sử dụng `grep_search` và `view_file` với `StartLine`/`EndLine` cụ thể. Không đọc file lướt trên diện rộng.
- **Targeted Edits**: Ưu tiên sử dụng `replace_file_content` thay vì ghi đè lại toàn bộ file.
- **Định tuyến chuyên biệt**:
  - **Sửa Neovim/LSP/Plugins**: Mở trực tiếp thư mục `home/dev/nvim/` và `home/nvim/lua/bamos/*`.
  - **Sửa Shell/Aliases/Prompt**: Mở trực tiếp `home/programs/shell/aliases.nix` hoặc `zsh.nix`.
  - **Sửa Desktop/GNOME**: Mở `modules/gnome/dconf.nix`, `extensions.nix`, `keybindings.nix`.
  - **Sửa Audio/PipeWire**: Mở `modules/audio/noise-suppression.nix` hoặc `low-latency.nix`.
  - **Sửa Power/TLP**: Mở `modules/power/tlp.nix`.
- **Tuyệt đối không đọc**: `assets/images/`, `assets/fonts/`, `assets/icons/`, `flake.lock`, `Cargo.lock`, `target/`, file nhị phân.

## 3. Clean Architecture & Micro-Modules Rules
- **Ngưỡng trần giới hạn dòng (Strict Ceiling)**:
  - Mọi file cấu hình NixOS / Home-Manager: **TỐI ĐA < 80 dòng/file**. Khi đạt ~70 dòng, chủ động tách thành micro-module con và dùng `default.nix` làm aggregator.
  - Mọi file mã nguồn Rust / C++ / Shell: **TỐI ĐA < 100 dòng/file**. Proactively tách nhỏ structs, helpers, components.
- **Strict FOSS & No Commercial License (Phi thương mại & Tự do 100%)**:
  - Mọi gói phần mềm, phông chữ và thư viện đồ họa tích hợp vào BamOS BẮT BUỘC có bản quyền nguồn mở tự do (GPL-3.0, MIT, Apache 2.0, BSD, SIL OFL).
  - Tuyệt đối không tích hợp thư viện, font hay theme có điều khoản bản quyền thương mại có phí.

## 4. Versioning Standard (`AA.BB.CC`) & Git Workflow
- **Định dạng**: `AA.BB.CC`
  - **`AA` (Năm)**: 2 chữ số cuối của năm hiện tại (ví dụ: năm 2026 -> `AA = 26`).
  - **`BB` (Milestone kiến trúc)**: Bắt đầu từ `01`. Tăng khi có tái cấu trúc nền tảng lớn toàn hệ thống.
  - **`CC` (Sprint / Release cycle)**: Bắt đầu từ `01`. Tăng sau mỗi lần hoàn thành sprint hoặc phát hành ISO/App mới (`v26.01.01` -> `v26.01.02`).
- **Quy định Nhánh Git**:
  - `develop`: Nhánh làm việc chính hàng ngày cho toàn bộ commit tính năng.
  - `main`: Nhánh ổn định (production/release). CHỈ merge từ `develop` vào `main` khi xong sprint kèm cập nhật `CC` và gắn Git Tag `vAA.BB.CC`.
- **Commit Standard**: Conventional Commits (`feat(...)`, `fix(...)`, `refactor(...)`, `docs(...)`, `chore(...)`).
- **Zero Bloat Invariant**: Không bao giờ commit file build derivations (`result`, `result-*`), ISO images, `.direnv`, `.devenv`, `target/`.

## 5. Agile Vibe Coding Pipeline (idea.md ➔ bk_idea.md)
Khi người dùng đưa ra yêu cầu mới (qua đoạn chat hoặc viết trong `idea.md`):
1. **Refine & Reframe**: AI Agent chủ động đọc hiểu, tinh chỉnh, cấu trúc hóa yêu cầu theo phong cách kỹ thuật chuẩn mực (Bối cảnh, Mục tiêu, Subsystem tác động, Thiết kế giải pháp đề xuất, Acceptance Criteria).
2. **Xác thực (Verification)**: Hỏi lại người dùng để đối soát và xác nhận nội dung diễn đạt đã đúng ý định và đầy đủ hay chưa.
3. **Lưu trữ & Đồng bộ**: Sau khi người dùng xác nhận, chuyển ý tưởng đã chuẩn hóa vào `bk_idea.md`, dọn sạch `idea.md` và tiến hành hiện thực hóa code.
