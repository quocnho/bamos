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
    description = "Cài công cụ phát triển (Zed, Antigravity, Python, Node, Go, devenv...)";
    type = lib.types.bool;
    default = false;
  };

  config = lib.mkIf config.my.dev.enable {
    environment.systemPackages = with pkgs; [
      # ---- IDE & tooling ----
      zed-editor
      nil # Nix language server (extension "Nix" của Zed + nix-ide trong Antigravity)
      devenv # devshell kiểu Nix, chạy cùng direnv (mọi môi trường Python, Node, Go... quản lý qua devenv)

      # ---- Antigravity (Google — AI IDE + CLI, unfree) ----
      antigravity-ide
      antigravity-cli

      # ---- GPU diagnostic ----
      mesa-demos # glxinfo... (kiểm tra GPU)
    ];

    # direnv: nạp env theo thư mục (dev chạy devenv/nix-direnv).
    # LƯU Ý: từ giờ direnv do HOME-MANAGER quản lý (home/dev.nix —
    # programs.direnv) để cấu hình nằm đúng tầng user, tránh trùng lặp.

    # ==== Zed editor: cấu hình (settings/keymap/skills) do HOME-MANAGER quản lý ====
    # User service `zed-settings` giờ định nghĩa trong home/dev.nix (home-manager)
    # — gói zed-editor vẫn cài ở đây (environment.systemPackages).

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
