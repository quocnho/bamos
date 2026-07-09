# hosts/lg/default.nix
# Developer laptop — LG Gram (i5-10210U, GTX 1650)
# flake-parts module → nixosConfigurations.lg
{ self, inputs, ... }:
{
  flake.nixosConfigurations.lg = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      # BamOS core modules
      self.nixosModules.default

      # Agenix — secret management
      inputs.agenix.nixosModules.default

      # Home-manager — user-level config
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          users.quocnho = import ./home.nix;
        };
      }

      # Host-specific: hardware scan + local config
      ./hardware-configuration.nix
      ./configuration.nix
    ];
  };
}
