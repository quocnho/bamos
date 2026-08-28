# Công cụ PHÁT TRIỂN — chỉ cài trên máy dev (bật qua my.dev.enable = true
# ở hosts/<máy>.nix). Máy người dùng cuối (cài từ ISO) KHÔNG cài các gói này
# để distro gọn nhẹ — chỉ có công cụ cơ bản trong modules/packages.nix.
#
# Bật trên máy LG:  my.dev.enable = true;   (hosts/lg.nix)
{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.my.dev.enable = lib.mkOption {
    description = "Cài công cụ phát triển (Zed, Antigravity, Python, Node, devenv...)";
    type = lib.types.bool;
    default = false;
  };

  config = lib.mkIf config.my.dev.enable {
    environment.systemPackages = with pkgs; [
      # ---- IDE & tooling ----
      zed-editor
      nil # Nix language server (extension "Nix" của Zed + nix-ide trong Antigravity)
      devenv # devshell kiểu Nix, chạy cùng direnv

      # ---- Python (môi trường lập trình) ----
      python3
      python3Packages.pip
      python3Packages.virtualenv
      uv

      # ---- Node.js (JavaScript/TypeScript) ----
      nodejs # Node LTS + npm đi kèm
      pnpm # quản lý package nhanh, tiết kiệm dung lượng

      # ---- Antigravity (Google — AI IDE + CLI, unfree) ----
      antigravity-ide
      antigravity-cli

      # ---- Container / hệ thống ----
      distrobox
      podman-compose
      mesa-demos # glxinfo... (kiểm tra GPU)
    ];

    # direnv: nạp env theo thư mục (dev chạy devenv/nix-direnv)
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

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
    systemd.user.services.antigravity-settings = {
      wantedBy = [ "default.target" ];
      path = [ pkgs.python3 ];
      script = ''
        python3 ${./../assets/antigravity/sync.py} ${./../assets/antigravity}
      '';
    };
  };
}
