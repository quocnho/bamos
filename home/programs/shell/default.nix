# Description: Aggregator cấu hình Shell (Zsh, Starship, Aliases, Helpers) (< 20 dòng)
{ ... }:

{
  imports = [
    ./zsh.nix
    ./aliases.nix
    ./starship.nix
    ./helpers.nix
  ];
}
