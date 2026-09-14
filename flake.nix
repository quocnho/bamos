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

      packages.${system} = {
        # Troly - Native Edge AI Desktop Companion (C++20, Qt6)
        troly = nixpkgs.legacyPackages.${system}.callPackage ./pkgs/troly { };
        # BamOS CLI — cài qua environment.systemPackages (modules/packages.nix),
        # hoặc build độc lập: nix build .#bam
        bam = nixpkgs.legacyPackages.${system}.callPackage ./pkgs/bam { };
        # ISO cài đặt cho người dùng khác
        iso = self.nixosConfigurations.installer.config.system.build.isoImage;
        # toplevel máy chính (nix build .)
        default = self.nixosConfigurations.lg.config.system.build.toplevel;
      };
    };
}
