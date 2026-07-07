# lib/mkHost.nix
# Helper function — tạo nixosConfiguration từ host name + profile
# Usage:
#   mkHost {
#     name = "lg";
#     profile = "gnome-developers";
#     system = "x86_64-linux";
#   }
{ lib
, self
, name
, profile
, system ? "x86_64-linux"
,
}:
lib.nixosSystem {
  inherit system;
  modules = [
    self.nixosModules.default
    (import ../profiles/${profile}.nix)
    (import ../hosts/${name}/configuration.nix)
    (import ../hosts/${name}/hardware-configuration.nix)
  ];
}
