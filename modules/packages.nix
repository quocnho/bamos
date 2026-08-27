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

    # ==== Node.js (JavaScript/TypeScript — luôn sẵn sàng) ====
    nodejs         # Node LTS + npm đi kèm
    pnpm           # quản lý package nhanh, tiết kiệm dung lượng

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

  # ==== Antigravity IDE + CLI: cấu hình chuyên nghiệp (declarative) ====
  # Asset nằm ở assets/antigravity/ (settings.json, mcp_config.json, skills/).
  # User service chạy mỗi lần đăng nhập:
  #   1. MERGE settings.json vào ~/.config/Antigravity IDE/User/settings.json
  #   2. MERGE mcp_config.json vào ~/.gemini/config/mcp_config.json (giữ entry đã có)
  #   3. Đồng bộ skills/ vào ~/.gemini/config/skills/ (assets là nguồn chuẩn)
  # Sửa asset rồi rebuild (hoặc đăng nhập lại) để áp dụng.
  systemd.user.services.antigravity-settings = {
    wantedBy = [ "default.target" ];
    path = [ pkgs.python3 ];
    script = ''
      python3 - ${./../assets/antigravity} <<'PY'
import json, os, pathlib, re, shutil, sys

assets = pathlib.Path(sys.argv[1])
home = pathlib.Path.home()

def jsonc_loads(text):
    # Parse JSONC: bỏ comment // bên ngoài chuỗi (giữ nguyên https:// bên trong)
    out, in_str, i = [], False, 0
    while i < len(text):
        c = text[i]
        if in_str:
            out.append(c)
            if c == '\\':
                out.append(text[i + 1]); i += 2; continue
            if c == '"':
                in_str = False
        else:
            if c == '"':
                in_str = True; out.append(c)
            elif c == '/' and i + 1 < len(text) and text[i + 1] == '/':
                while i < len(text) and text[i] != '\n':
                    i += 1
                continue
            else:
                out.append(c)
        i += 1
    return json.loads("".join(out))

def load(p):
    if not p.exists():
        return {}
    try:
        return jsonc_loads(p.read_text())
    except Exception:
        return {}

# ---------- 1. IDE settings ----------
ide_dir = home / ".config/Antigravity IDE/User"
ide_dir.mkdir(parents=True, exist_ok=True)
settings_path = ide_dir / "settings.json"
merged = load(settings_path)
merged.update(load(assets / "settings.json"))
settings_path.write_text(json.dumps(merged, indent=2) + "\n")

# ---------- 2. MCP config (giữ entry người dùng đã chỉnh sửa) ----------
gemini = home / ".gemini/config"
gemini.mkdir(parents=True, exist_ok=True)
mcp_path = gemini / "mcp_config.json"
mcp = load(mcp_path)
servers = mcp.setdefault("mcpServers", {})

with (assets / "mcp_config.json").open() as f:
    asset_mcp = jsonc_loads(f.read())["mcpServers"]

for name, cfg in asset_mcp.items():
    template = json.dumps(cfg, sort_keys=True).replace("__HOME__", str(home))
    if name not in servers:
        servers[name] = json.loads(template)  # thêm mới
    elif json.dumps(servers[name], sort_keys=True) == template:
        servers[name] = json.loads(template)  # giống template → đồng bộ lại (vd: thay __HOME__)
    # khác template → giữ nguyên bản người dùng đã sửa (không đè)

mcp_path.write_text(json.dumps(mcp, indent=2) + "\n")

# ---------- 3. Skills (assets là nguồn chuẩn) ----------
def make_writable(path):
    # Nix store file có mode 444/555 — copytree giữ nguyên nên phải sửa lại
    for root, dirs, files in os.walk(path, topdown=False):
        for f in files:
            os.chmod(os.path.join(root, f), 0o644)
        os.chmod(root, 0o755)
    os.chmod(path, 0o755)

skills_dst = gemini / "skills"
skills_dst.mkdir(parents=True, exist_ok=True)
for src in (assets / "skills").iterdir():
    if src.is_dir():
        dst = skills_dst / src.name
        if dst.exists():
            make_writable(dst)
            shutil.rmtree(dst)
        shutil.copytree(src, dst)
        make_writable(dst)
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
