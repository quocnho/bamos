{
  description = "Bamos — cấu hình NixOS declarative (hosts + profiles + ISO installer)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    bam-customizer = {
      url = "git+ssh://git@github.com/quocnho/bam-customizer.git?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      bam-customizer,
      ...
    }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
      bamCustomizerOverlay = final: prev: {
        bam-customizer = bam-customizer.packages.${system}.default;
      };
    in
    {
      nixosModules.default = ./modules/default.nix;

      homeModules = {
        default = ./home/default.nix;
        dev = ./home/dev.nix;
      };

      profiles = {
        common = ./profiles/common.nix;
        desktop = ./profiles/desktop.nix;
        standard = ./profiles/standard.nix;
        dev = ./profiles/dev.nix;
        studio = ./profiles/studio.nix;
        gaming = ./profiles/gaming.nix;
        installer = ./profiles/installer.nix;
      };

      nixosConfigurations = {
        lg = lib.nixosSystem {
          inherit system;
          modules = [
            { nixpkgs.overlays = [ bamCustomizerOverlay ]; }
            ./configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "hm-bak";
                users.quocnho = import ./home/lg.nix;
              };
            }
          ];
        };

        installer = lib.nixosSystem {
          inherit system;
          modules = [
            { nixpkgs.overlays = [ bamCustomizerOverlay ]; }
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-gnome.nix"
            ./hosts/installer.nix
          ];
        };
      };

      packages.${system} = {
        bam = nixpkgs.legacyPackages.${system}.callPackage ./pkgs/bam { };
        bam-customizer = bam-customizer.packages.${system}.default;
        iso = self.nixosConfigurations.installer.config.system.build.isoImage;
        default = self.nixosConfigurations.lg.config.system.build.toplevel;
      };
    };
}
