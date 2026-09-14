{ pkgs, ... }:

{
  # ============================================================================
  # BamOS Monorepo Orchestration Dev Environment
  # Cung cấp bộ công cụ điều phối cho:
  # - Toàn bộ Linux Distro (/etc/nixos)
  # - Package Troly (C++20, Qt6)
  # - Package Assistant (Go, GTK3, WebKitGTK)
  # - Package Bam CLI (Bash)
  # ============================================================================

  languages.cplusplus.enable = true;
  languages.go.enable = true;

  packages = with pkgs; [
    # C++20 / Qt6 Toolchain (pkgs/troly)
    cmake
    ninja
    pkg-config
    gcc13
    gdb
    clang-tools
    sqlite
    sqlite-vec
    qt6.qtbase
    qt6.qtdeclarative

    # Go Toolchain (pkgs/assistant)
    gopls
    golangci-lint
    gtk3
    webkitgtk_4_1

    # Distro & Flake Management
    nixfmt
    statix
    git
  ];

  env = {
    CMAKE_BUILD_PARALLEL_LEVEL = "4";
    QT_QPA_PLATFORM = "wayland;xcb";
    CGO_ENABLED = "1";
  };

  # ---- Lệnh điều phối dự án con Troly (C++20 / Qt6) ----
  scripts."troly-build".exec = ''
    cmake -B pkgs/troly/build -S pkgs/troly -G Ninja -DCMAKE_BUILD_TYPE=Debug
    cmake --build pkgs/troly/build -j$(nproc)
  '';
  scripts."tb".exec = ''
    cmake -B pkgs/troly/build -S pkgs/troly -G Ninja -DCMAKE_BUILD_TYPE=Debug
    cmake --build pkgs/troly/build -j$(nproc)
  '';

  scripts."troly-run".exec = ''
    ./pkgs/troly/build/troly
  '';
  scripts."tr".exec = ''
    ./pkgs/troly/build/troly
  '';

  scripts."troly-preview".exec = ''
    qml6 pkgs/troly/src/presentation/ui/main.qml
  '';
  scripts."tp".exec = ''
    qml6 pkgs/troly/src/presentation/ui/main.qml
  '';

  # ---- Lệnh điều phối dự án con Assistant (Go / GTK) ----
  scripts."assistant-build".exec = ''
    (cd pkgs/assistant && go build -o build/bamos-assistant .)
  '';
  scripts."ab".exec = ''
    (cd pkgs/assistant && go build -o build/bamos-assistant .)
  '';

  scripts."assistant-run".exec = ''
    ./pkgs/assistant/build/bamos-assistant
  '';
  scripts."ar".exec = ''
    ./pkgs/assistant/build/bamos-assistant
  '';

  # ---- Lệnh quản trị & kiểm thử hệ điều hành BamOS Distro ----
  scripts."distro-dry".exec = ''
    nix build .#default --dry-run
  '';
  scripts."dd".exec = ''
    nix build .#default --dry-run
  '';

  scripts."distro-build".exec = ''
    nix build .#default
  '';
  scripts."db".exec = ''
    nix build .#default
  '';

  scripts."distro-iso".exec = ''
    nix build .#iso
  '';
  scripts."di".exec = ''
    nix build .#iso
  '';
}

