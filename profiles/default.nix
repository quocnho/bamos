# profiles/ — Tổ hợp modules cho từng edition+DE
# Mỗi profile = imports các modules cần thiết + set tham số
# KHÔNG khai báo options mới — chỉ imports
{ inputs, ... }:
{
  # Profile cho mỗi tổ hợp DE × Edition
  # Hiện tại chỉ có GNOME Standard là active

  gnome-standard = import ./gnome-standard.nix { inherit inputs; };
  gnome-developers = import ./gnome-developers.nix { inherit inputs; };
  gnome-gaming = import ./gnome-gaming.nix { inherit inputs; };
  gnome-studio = import ./gnome-studio.nix { inherit inputs; };

  kde-standard = import ./kde-standard.nix { inherit inputs; };
  kde-developers = import ./kde-developers.nix { inherit inputs; };
  kde-gaming = import ./kde-gaming.nix { inherit inputs; };
  kde-studio = import ./kde-studio.nix { inherit inputs; };

  cosmic-standard = import ./cosmic-standard.nix { inherit inputs; };
  cosmic-developers = import ./cosmic-developers.nix { inherit inputs; };
  cosmic-gaming = import ./cosmic-gaming.nix { inherit inputs; };
  cosmic-studio = import ./cosmic-studio.nix { inherit inputs; };
}
