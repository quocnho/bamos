{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "troly-dev-shell";

  nativeBuildInputs = with pkgs; [
    cmake
    ninja
    pkg-config
    gcc13
    gdb
    clang-tools
  ];

  buildInputs = with pkgs; [
    qt6.qtbase
    qt6.qtdeclarative
    sqlite
    sqlite-vec
  ];

  shellHook = ''
    export QT_QPA_PLATFORM="wayland;xcb"
    export CMAKE_BUILD_PARALLEL_LEVEL="$(nproc)"
    echo "=================================================="
    echo "🚀 Troly C++20 + Qt6 Dev Shell Ready"
    echo "=================================================="
  '';
}
