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

## 2. Token Saving Guidelines for AI
- **Sửa Neovim/LSP/Plugins**: Mở trực tiếp thư mục `home/dev/nvim/` và `home/nvim/lua/bamos/*`.
- **Sửa Shell/Aliases/Prompt**: Mở trực tiếp `home/programs/shell/aliases.nix` hoặc `zsh.nix`.
- **Sửa Desktop/GNOME**: Mở `modules/gnome/dconf.nix`, `extensions.nix`, `keybindings.nix`.
- **Sửa Audio/PipeWire**: Mở `modules/audio/noise-suppression.nix` hoặc `low-latency.nix`.
- **Sửa Power/TLP**: Mở `modules/power/tlp.nix`.
- **Tuyệt đối không đọc**: `assets/images/`, `assets/fonts/`, `flake.lock`.
