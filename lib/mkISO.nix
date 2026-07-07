# lib/mkISO.nix
# Helper function — extract ISO package from nixosConfiguration
# Usage:
#   iso-gnome-standard = import ./lib/mkISO.nix {
#     nixosConfiguration = self.nixosConfigurations.iso-gnome-standard;
#   };
{ nixosConfiguration
,
}:
nixosConfiguration.config.system.build.images.iso
