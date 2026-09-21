# BamOS Codebase Architecture & Context Map

> **Dành cho AI Assistants (Gemini, Claude, GPT, Antigravity, Cursor, Zed):**
> Đọc tài liệu này trước để định tuyến trực tiếp đến đúng file cần sửa. Không quét/grep diện rộng trên toàn bộ repo.

## 1. Directory Structure Map

```text
/etc/nixos/
├── flake.nix                # Root Flake: hosts (lg, installer), packages (bam, iso), modules export
├── configuration.nix        # Fallback entrypoint cho legacy nixos-rebuild
├── hosts/                   # Cấu hình cụ thể từng máy (Hardware + Custom module flags)
│   ├── lg.nix               # Máy dev chính (Optimus Intel + NVIDIA, Studio, Dev, Home-manager)
│   └── installer.nix        # Cấu hình build Live ISO Calamares
├── profiles/                # Base profiles (common, desktop, installer)
├── modules/                 # System-level NixOS modules (bật tắt qua `my.<module>.enable`)
│   ├── boot.nix             # GRUB / Systemd-boot kernel params
│   ├── gpu.nix              # NVIDIA PRIME / Intel graphics
│   ├── power.nix            # TLP / TLP-UI / thermald / powertop
│   ├── audio.nix            # PipeWire / WirePlumber
│   ├── gnome.nix            # GNOME Desktop, Dconf, GDM, Extensions
│   ├── macos.nix            # macOS theme / keybindings / dock
│   ├── assets.nix           # Wallpapers, fonts system-wide
│   ├── i18n.nix             # Locale, Timezone, Fcitx5 tiếng Việt (Bamboo)
│   ├── dev.nix              # Dev packages cấp hệ thống (Zed, Antigravity, Docker, etc.)
│   ├── studio.nix           # OBS, NVENC/VAAPI, video/audio production
│   ├── studio/fonts.nix     # Fonts sáng tạo cho OBS/Studio
│   ├── update.nix           # Auto-update timer & services
│   ├── update/              # Shell scripts hỗ trợ tự động update
│   └── default.nix          # Module aggregator
├── home/                    # User-level configurations (Home-Manager)
│   ├── default.nix          # User base aggregator (bamos.homeModules.default)
│   ├── lg.nix               # User specific cho máy lg (git quocnho, dev import)
│   ├── programs/            # Shell, CLI, Git
│   │   ├── shell.nix        # Zsh, Starship, Fzf, Zoxide, Aliases
│   │   ├── git.nix          # Git, Delta pager, SSH config
│   │   └── cli.nix          # Tiện ích CLI: jq, yq, ripgrep, btop...
│   ├── dev/                 # Developer tools (bamos.homeModules.dev)
│   │   ├── default.nix      # Dev module aggregator
│   │   ├── nvim.nix         # Neovim plugins, LSP extraPackages, lua links
│   │   ├── tmux.nix         # Tmux + tmux plugins
│   │   ├── zed.nix          # Zed editor sync user service
│   │   └── tools.nix        # Direnv, gh, lazygit, dev cli packages
│   └── dev.nix              # Shim giữ tương thích ngược trỏ vào home/dev/default.nix
├── pkgs/                    # Custom derivations viết riêng
│   └── bam/                 # Bam CLI tool (`bam switch`, `bam update`, etc.)
└── assets/                  # Tài nguyên tĩnh (Static Assets - KHÔNG ĐỌC trừ khi được yêu cầu)
    ├── fonts/               # Font files nhị phân (.ttf, .otf)
    ├── images/              # Wallpapers (.jpg, .png)
    └── zed/, antigravity/   # Editor configs & skills template
```

## 2. Token Saving Guidelines for AI
- **Sửa Neovim/LSP/Plugins**: Mở trực tiếp `home/dev/nvim.nix` và `home/nvim/lua/bamos/*`.
- **Sửa Shell/Aliases/Prompt**: Mở trực tiếp `home/programs/shell.nix`.
- **Sửa Git/SSH**: Mở trực tiếp `home/programs/git.nix`.
- **Sửa Dev CLI/Direnv/Tmux**: Mở `home/dev/tools.nix` hoặc `home/dev/tmux.nix`.
- **Sửa System Modules**: Mở đúng module trong `modules/<name>.nix`.
- **Tuyệt đối không đọc**: `assets/images/`, `assets/fonts/`, `flake.lock`.
