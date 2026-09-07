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

      # ---- Toolchain build (C/C++/CMake/node-gyp...) ----
      # NixOS reproducible: hệ thống KHÔNG phơi bày compiler sẵn — máy dev cần
      # build native (node-gyp, pip wheel, cmake project, cấu trúc C…) nên cài
      # sẵn bộ toolchain. LƯU Ý glibc (runtime + headers) ĐÃ có qua /nix/store,
      # gcc wrapper tự trỏ tới — không cần thêm glibc.dev vào systemPackages.
      gcc # C/C++ (gcc + g++), kèm header libc chuẩn
      binutils # ld, as, strip, ar...
      gnumake # make
      pkg-config # tìm thư viện/header khi build (CFLAGS/LDFLAGS)
      cmake # build system phổ biến
      ninja # build nhanh (cmake -G Ninja)
      autoconf # build từ source (./configure) — autotools
      automake
      libtool
      m4
      patch
      file # nhiều script ./configure cần xác định loại file
      # clang # bỏ comment nếu build project cần clang (vd Rust bindgen, Zig...)
      # openssl # bỏ comment nếu build native cần thư viện openssl (headers đi kèm dev)
    ];

    # direnv: nạp env theo thư mục (dev chạy devenv/nix-direnv).
    # LƯU Ý: từ giờ direnv do HOME-MANAGER quản lý (home/dev.nix —
    # programs.direnv) để cấu hình nằm đúng tầng user, tránh trùng lặp.

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
