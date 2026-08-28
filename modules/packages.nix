# Gói phần mềm cài sẵn toàn hệ thống.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    # BamOS CLI — 1 lệnh `bam` quản lý hệ thống (switch/boot/iso/gc/info/doctor...)
    (callPackage ../pkgs/bam { })

    # Core Tools
    zed-editor
    nil # Nix language server (extension "Nix" của Zed + nix-ide trong Antigravity)
    git
    vim
    wget
    curl
    distrobox
    mesa-demos
    pciutils
    gparted
    unzip
    zip
    unrar

    # Audio / Ghi âm (tham khảo GLF-OS)
    ffmpeg

    # Dev Environment (devenv — devshell kiểu Nix, chạy cùng direnv)
    devenv

    # ==== Python (môi trường lập trình — luôn sẵn sàng) ====
    python3
    python3Packages.pip
    python3Packages.virtualenv
    uv

    # ==== Node.js (JavaScript/TypeScript — luôn sẵn sàng) ====
    nodejs # Node LTS + npm đi kèm
    pnpm # quản lý package nhanh, tiết kiệm dung lượng

    # ==== Antigravity (Google — AI IDE + CLI, unfree) ====
    antigravity-ide
    antigravity-cli

    # Terminal UI
    # (fzf + starship + zoxide được cài qua programs.* trong modules/shell.nix)
    fd
    bat
    eza
    htop
    direnv
    podman-compose

    # GNOME Extensions & Tools (bản đầy đủ trong modules/gnome.nix)
    gnome-extension-manager
  ];

  # ==== Zed editor: font lớn + cấu hình chuyên nghiệp (declarative) ====
  # File settings nằm ở assets/zed/settings.json — sửa ở đó rồi rebuild.
  # User service chạy mỗi lần đăng nhập:
  #   1. MERGE settings.json vào ~/.config/zed/settings.json (KHÔNG đè "agent")
  #   2. Đồng bộ skills/ vào ~/.config/zed/skills/ (assets là nguồn chuẩn)
  # Thay __HOME__ trong settings (dùng cho context server fs).
  systemd.user.services.zed-settings = {
    wantedBy = [ "default.target" ];
    path = [ pkgs.python3 ];
    script = ''
      mkdir -p "$HOME/.config/zed"
      python3 ${./../assets/zed/sync.py} ${./../assets/zed}
    '';
  };

  # ==== Antigravity IDE + CLI: cấu hình chuyên nghiệp (declarative) ====
  # Asset nằm ở assets/antigravity/ (settings.json, mcp_config.jsonc, skills/).
  # User service chạy mỗi lần đăng nhập:
  #   1. MERGE settings.json vào ~/.config/Antigravity IDE/User/settings.json
  #   2. MERGE mcp_config.jsonc (JSONC) vào ~/.gemini/config/mcp_config.json (giữ entry đã có)
  #   3. Đồng bộ skills/ vào ~/.gemini/config/skills/ (assets là nguồn chuẩn)
  # Sửa asset rồi rebuild (hoặc đăng nhập lại) để áp dụng.
  systemd.user.services.antigravity-settings = {
    wantedBy = [ "default.target" ];
    path = [ pkgs.python3 ];
    script = ''
      python3 ${./../assets/antigravity/sync.py} ${./../assets/antigravity}
    '';
  };

  # ==== Firefox (cài qua programs.firefox để kèm policies tối ưu PIN) ====
  # - VAAPI hardware video decode trên Intel iGPU (iHD): xem video tiết kiệm pin
  # - Tự xả tab khi thiếu RAM
  programs.firefox = {
    enable = true;
    policies = {
      Preferences = {
        "media.ffmpeg.vaapi.enabled" = true;
        "media.hardware-video-decoding.enabled" = true;
        "browser.tabs.unloadOnLowMemory" = true;
      };
    };
  };
}
