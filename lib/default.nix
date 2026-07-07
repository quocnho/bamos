# lib/ — Thư viện & hàm dùng chung
# Các hàm mkEdition, mkHost, mkISO — logic tái sử dụng cao
# Không chứa config — chỉ pure functions
{ inputs, ... }:
{
  # mkEdition: Tạo edition profile từ DE + edition type
  # Usage: mkEdition { desktop = "gnome"; edition = "gaming"; }
  mkEdition =
    { desktop, edition }:
    import ../profiles/${desktop}-${edition}.nix { inherit inputs; };

  # mkHost: Tạo nixosConfiguration từ host definition
  # Usage: mkHost { name = "lg"; profile = "gnome-developers"; }
  mkHost =
    { name, profile }:
    {
      imports = [
        (import ../profiles/${profile}.nix { inherit inputs; })
        (import ../hosts/${name} { inherit inputs; })
      ];
    };

  # mkISO: Build ISO từ profile
  # Usage: mkISO { profile = "gnome-standard"; }
  mkISO =
    { profile }:
    import ../hosts/iso/profiles/${profile}.nix { inherit inputs; };
}
