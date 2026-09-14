# ============================================================================
# BamOS Monorepo Orchestration Justfile
# Chạy `just` hoặc `just --list` để xem danh sách công thức.
# ============================================================================

set shell := ["bash", "-uc"]

default:
    @just --list

# ----------------------------------------------------------------------------
# Troly C++20 / Qt6 Desktop Companion
# ----------------------------------------------------------------------------

# Biên dịch dự án troly (C++20, Qt6, CMake, Ninja)
[group('troly')]
troly-build:
    cmake -B pkgs/troly/build -S pkgs/troly -G Ninja -DCMAKE_BUILD_TYPE=Debug
    cmake --build pkgs/troly/build -j$(nproc)

alias tb := troly-build

# Chạy ứng dụng troly
[group('troly')]
troly-run:
    ./pkgs/troly/build/troly

alias tr := troly-run

# Xem trước giao diện QML của troly
[group('troly')]
troly-preview:
    qml pkgs/troly/src/presentation/ui/main.qml

alias tp := troly-preview

# ----------------------------------------------------------------------------
# BamOS Assistant Go / GTK3 / WebKitGTK
# ----------------------------------------------------------------------------

# Biên dịch dự án assistant (Go, GTK3, WebKitGTK)
[group('assistant')]
assistant-build:
    cd pkgs/assistant && go build -o build/bamos-assistant .

alias ab := assistant-build

# Chạy ứng dụng assistant
[group('assistant')]
assistant-run:
    ./pkgs/assistant/build/bamos-assistant

alias ar := assistant-run

# ----------------------------------------------------------------------------
# BamOS Linux Distro Management
# ----------------------------------------------------------------------------

# Dry-run xem trước thay đổi build hệ thống
[group('distro')]
distro-dry:
    nix build .#default --dry-run

alias dd := distro-dry

# Build toplevel hệ thống BamOS
[group('distro')]
distro-build:
    nix build .#default

alias db := distro-build

# Build ISO cài đặt BamOS
[group('distro')]
distro-iso:
    nix build .#iso

alias di := distro-iso
