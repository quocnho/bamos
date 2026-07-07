# modules/editions/default.nix
{ ... }: {
  imports = [
    ./developers.nix
    ./gaming.nix
    ./studio.nix
  ];
}
