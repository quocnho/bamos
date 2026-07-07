# lib/mkEdition.nix
# Helper — tạo edition profile từ DE + edition type
# Cách dùng:
#   mkEdition { desktop = "gnome"; edition = "gaming"; }
#   → imports core + desktop/gnome + editions/gaming + theming
{ desktop ? "gnome"
, edition ? "standard"
,
}:

{
  imports = [
    # Core system (always included)
    ../modules/core/system.nix
    ../modules/core/locale.nix
    ../modules/core/audio.nix
    ../modules/core/input-method.nix
    ../modules/core/optimization.nix
    ../modules/core/fonts.nix

    # Desktop Environment
    ../modules/desktop/${desktop}.nix

    # Hardware (generic)
    ../modules/hardware/network.nix
  ];
}
