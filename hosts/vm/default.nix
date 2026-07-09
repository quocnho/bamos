# hosts/vm/default.nix
# QEMU test VM — test BamOS config trong máy ảo
# Cách dùng:
#   nixos-rebuild build-vm --flake .#vm
#   ./result/bin/run-bamos-vm
#
# Hoặc test ISO:
#   nix build .#iso-gnome-standard
#   qemu-system-x86_64 -enable-kvm -m 4G -cdrom result/iso/*.iso
#
{ self, inputs, ... }:
{
  flake.nixosConfigurations.vm = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      # BamOS core modules
      self.nixosModules.default

      # Profile: chọn edition muốn test (gnome-standard, kde-gaming, cosmic-studio...)
      (import ../../profiles/gnome-standard.nix)

      # VM-specific config
      {
        networking.hostName = "bamos-vm";
        system.stateVersion = "26.05";
        services.qemuGuest.enable = true;
        services.openssh.enable = true;
      }
    ];
  };
}
