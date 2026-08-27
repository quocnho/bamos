{
  description = "Cấu hình NixOS với Flakes (LG laptop)";

  inputs = {
    # Nguồn gói phần mềm, hiện đang trỏ tới nhánh unstable
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    # Các module NixOS dùng chung — cấu trúc tương tự flake-parts:
    # mỗi module nằm trong ./modules, được gom qua ./modules/default.nix.
    nixosModules = {
      default = ./modules/default.nix;
    };

    nixosConfigurations = {
      # Host "lg" — laptop LG (Intel UHD CometLake + NVIDIA GTX 1650)
      lg = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
        ];
      };
    };
  };
}
