# Description: Profile INSTALLER aggregator (< 25 dòng)
{ ... }:

{
  imports = [
    ./calamares.nix
    ./iso.nix
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
}
