{
  description = "Bamos — cấu hình NixOS declarative (hosts + profiles + ISO installer)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home-manager — quản lý cấu hình NGƯỜI DÙNG ($HOME): gói riêng của user,
    # git config, dotfiles... (dùng chung nixpkgs với hệ thống → useGlobalPkgs).
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      # Module dùng chung (aggregator modules/default.nix) — khớp mẫu website
      # bamos.info: `bamos.nixosModules.default` trong flake của máy đích.
      nixosModules.default = ./modules/default.nix;

      # Home-manager dùng chung — máy đích (cài từ ISO) dùng qua
      # `bamos.homeModules.*` trong iso-cfg/flake.nix.
      homeModules = {
        default = ./home/default.nix; # nền tảng: shell, git, ssh (mọi máy)
        dev = ./home/dev.nix; # developer: nvim, tmux, gh, direnv (bật riêng)
      };

      # Profiles dùng chung — máy đích (cài từ ISO) import qua `bamos.profiles.*`
      # trong flake của họ (xem iso-cfg/flake.nix).
      profiles = {
        common = ./profiles/common.nix; # nền tảng: module chung + audio
        desktop = ./profiles/desktop.nix; # GNOME + macOS look + boot + fonts
        installer = ./profiles/installer.nix; # LiveCD (isoImage + Calamares override)
      };

      nixosConfigurations = {
        # LG laptop — máy chính (host).
        lg = lib.nixosSystem {
          inherit system;
          modules = [
            ./configuration.nix
            # Home-manager: cấu hình user quocnho (home/lg.nix → kế thừa home/default.nix)
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true; # dùng chung nixpkgs với hệ thống
                useUserPackages = true; # gói user vào ~/.nix-profile (qua users.users.*.packages)
                backupFileExtension = "hm-bak"; # file $HOME trùng tên → backup thay vì lỗi
                users.quocnho = import ./home/lg.nix;
              };
            }
          ];
        };

        # ISO installer — build bằng: nix build .#iso
        # (LiveCD GNOME + Calamares của nixpkgs + profile installer override)
        installer = lib.nixosSystem {
          inherit system;
          modules = [
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-gnome.nix"
            ./hosts/installer.nix
          ];
        };
      };

      # Packages hỗ trợ đa nền tảng
      packages = forAllSystems (sys:
        let
          pkgs = nixpkgs.legacyPackages.${sys};
        in
        {
          # Troly - Native Edge AI Desktop Companion (C++20, Qt6)
          troly = pkgs.callPackage ./pkgs/troly { };

          # BamOS Assistant - Legacy Go/GTK3 Assistant
          assistant = pkgs.callPackage ./pkgs/assistant { };

          # BamOS CLI — quản lý hệ thống
          bam = pkgs.callPackage ./pkgs/bam { };

          # ISO cài đặt (chỉ build trên x86_64-linux)
          iso = if sys == "x86_64-linux" then self.nixosConfigurations.installer.config.system.build.isoImage else null;

          # toplevel máy chính
          default = if sys == "x86_64-linux" then self.nixosConfigurations.lg.config.system.build.toplevel else null;
        }
      );

      # DevShells độc lập cho từng subproject & quản trị OS mẹ
      devShells = forAllSystems (sys:
        let
          pkgs = nixpkgs.legacyPackages.${sys};
        in
        {
          # Shell quản trị toàn hệ thống BamOS Flake
          default = pkgs.mkShell {
            name = "bamos-distro-dev";
            nativeBuildInputs = with pkgs; [
              git
              nixfmt-rfc-style
              statix
              nix-diff
            ];
            shellHook = ''
              echo "🚀 BamOS Linux Distro Root DevShell Ready"
            '';
          };

          # Shell chuyên biệt cho Troly (C++20, Qt6, CMake, Ninja)
          # Kế thừa tự động từ derivation pkgs/troly/default.nix
          troly = pkgs.mkShell {
            name = "troly-dev-shell";
            inputsFrom = [ self.packages.${sys}.troly ];
            nativeBuildInputs = with pkgs; [
              gdb
              clang-tools
              qt6.qtdeclarative
            ];
            shellHook = ''
              export QT_QPA_PLATFORM="wayland;xcb"
              export CMAKE_BUILD_PARALLEL_LEVEL="$(nproc)"
              export QML2_IMPORT_PATH="${pkgs.qt6.qtdeclarative}/lib/qt-6/qml"
              export QT_PLUGIN_PATH="${pkgs.qt6.qtsvg}/lib/qt-6/plugins:$QT_PLUGIN_PATH"
              export SQLITE_VEC_PATH="${pkgs.sqlite-vec}/lib/vec0.so"
              echo "🐾 Troly C++20/Qt6 DevShell Active (Zero-Drift inputsFrom)"
            '';
          };

          # Shell chuyên biệt cho Assistant (Go 1.22+, GTK3, WebKitGTK)
          # Kế thừa tự động từ derivation pkgs/assistant/default.nix
          assistant = pkgs.mkShell {
            name = "assistant-dev-shell";
            inputsFrom = [ self.packages.${sys}.assistant ];
            nativeBuildInputs = with pkgs; [
              go
              gopls
              golangci-lint
            ];
            shellHook = ''
              export CGO_ENABLED=1
              echo "🤖 BamOS Assistant Go/GTK DevShell Active (Zero-Drift inputsFrom)"
            '';
          };
        }
      );
    };

}
