{ pkgs, ... }:

{
  # Tùy biến môi trường phát triển C++20 + Qt6 + SQLite cho dự án troly
  languages.cplusplus.enable = true;

  packages = with pkgs; [
    cmake
    ninja
    pkg-config
    gcc13
    gdb
    clang-tools
    sqlite
    sqlite-vec

    # Qt6 packages
    qt6.qtbase
    qt6.qtdeclarative
  ];

  env = {
    CMAKE_BUILD_PARALLEL_LEVEL = "4";
    QT_QPA_PLATFORM = "wayland;xcb";
  };

  scripts.build.exec = ''
    cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Debug
    cmake --build build -j$(nproc)
  '';

  scripts.run.exec = ''
    ./build/troly
  '';
}
