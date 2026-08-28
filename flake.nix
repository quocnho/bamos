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
      # Profiles dùng chung — máy đích (cài từ ISO) import qua `bamos.profiles.*`
      # trong flake của họ (xem installer/flake.nix).
      profiles = {
        common = ./profiles/common.nix; # nền tảng: module chung + audio
        desktop = ./profiles/desktop.nix; # GNOME + macOS look + boot + fonts
        installer = ./profiles/installer.nix; # LiveCD (isoImage + dialog installer)
      };

      nixosConfigurations = {
        # LG laptop — máy chính (host).
        lg = lib.nixosSystem {
          inherit system;
          modules = [ ./configuration.nix ];
        };

        # ISO installer — build bằng: nix build .#iso
        # (chồng module LiveCD console của nixpkgs + profile installer)
        installer = lib.nixosSystem {
          inherit system;
          modules = [
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
            ./hosts/installer.nix
          ];
        };
      };

      packages.${system} = {
        # ISO cài đặt cho người dùng khác
        iso = self.nixosConfigurations.installer.config.system.build.isoImage;
        # toplevel máy chính (nix build .)
        default = self.nixosConfigurations.lg.config.system.build.toplevel;
      };
    };
}
