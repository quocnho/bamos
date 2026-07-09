# hosts/vm/default.nix
# QEMU test VM — test BamOS config trong máy ảo
# Cách dùng:
#   nixos-rebuild build-vm --flake .#vm
#   ./result/bin/run-bamos-vm
#
# Lần đầu boot sẽ chậm do tạo disk + format (autoFormat)
# Sau đó boot nhanh bình thường
#
# Hoặc test ISO:
#   nix build .#iso-gnome-standard
#   qemu-system-x86_64 -enable-kvm -m 4G -cdrom result/iso/*.iso
#
{ self, inputs, lib, ... }:
{
  flake.nixosConfigurations.vm = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      # BamOS core modules
      self.nixosModules.default

      # Profile: chọn edition muốn test
      (import ../../profiles/gnome-standard.nix)

      # VM disk config — tránh lỗi "waiting for /dev/disk/by-label/nixos"
      {
        networking.hostName = "bamos-vm";
        system.stateVersion = "26.05";
        services.qemuGuest.enable = true;

        # Root filesystem trên ổ đĩa ảo build-vm
        fileSystems."/" = {
          device = "/dev/vda";
          fsType = "ext4";
          autoFormat = true;
        };

        # Boot partition
        fileSystems."/boot" = {
          device = "/dev/vda1";
          fsType = "vfat";
          autoFormat = true;
        };
      }
    ];
  };
}
