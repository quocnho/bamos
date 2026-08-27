# Gói phần mềm cài sẵn toàn hệ thống.
{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Core Tools
    zed-editor
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
  # User service chạy mỗi lần đăng nhập, MERGE cấu hình mặc định vào
  # ~/.config/zed/settings.json — KHÔNG đè block "agent" (quyền hạn Zed
  # agent đã được bạn duyệt sẽ được giữ nguyên).
  systemd.user.services.zed-settings = {
    wantedBy = [ "default.target" ];
    path = [ pkgs.python3 ];
    script = ''
      mkdir -p "$HOME/.config/zed"
      python3 - ${./../assets/zed/settings.json} <<'PY'
import json, sys, pathlib

settings_path = pathlib.Path.home() / ".config/zed/settings.json"
with open(sys.argv[1]) as f:
    defaults = json.load(f)

merged = {}
if settings_path.exists():
    try:
        merged = json.loads(settings_path.read_text())
    except Exception:
        merged = {}

# Áp dụng cấu hình mặc định (font, theme...), KHÔNG đụng "agent"
merged.update({k: v for k, v in defaults.items() if k != "agent"})
settings_path.write_text(json.dumps(merged, indent=2))
PY
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
