# hosts/vm/default.nix
# QEMU test VM — dùng để test ISO trong CI/CD hoặc local
# Sẽ được implement trong Sprint 2+
{ self, inputs, ... }:
{
  # flake.nixosConfigurations.vm = inputs.nixpkgs.lib.nixosSystem {
  #   system = "x86_64-linux";
  #   modules = [
  #     self.nixosModules.default
  #     (import ../../profiles/gnome-standard.nix)
  #     {
  #       # VM-specific: QEMU guest agent, virtual disk, etc.
  #     }
  #   ];
  # };
}
