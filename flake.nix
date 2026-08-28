{
  description = "Bamos — cấu hình NixOS declarative (hosts + profiles + ISO installer)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
    in
    {
      # Module dùng chung (aggregator modules/default.nix) — khớp mẫu website
      # bamos.info: `bamos.nixosModules.default` trong flake của máy đích.
      nixosModules.default = ./modules/default.nix;

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
          modules = [ ./configuration.nix ];
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
