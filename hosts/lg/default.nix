{ self, inputs, ... }:
{
  flake.nixosConfigurations.lg = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      # BamOS core modules
      self.nixosModules.default

      # Host-specific: hardware scan + local config
      ./hardware-configuration.nix
      ./configuration.nix
    ];
  };
}
