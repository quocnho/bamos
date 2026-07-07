# Collection of custom packages for BamOS.
# Add your custom derivations here.
#
# Usage (in flake.nix):
#   perSystem = { pkgs, ... }: {
#     packages = import ./pkgs pkgs;
#   };

pkgs:

{
  bamos-branding = pkgs.callPackage ./bamos-branding { };
}
