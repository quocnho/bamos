# modules/core/bamos-overlay.nix
# Apply BamOS overlays vào nixpkgs cho mọi nixosConfiguration
# Cho phép sử dụng pkgs.bamos-branding, pkgs.bam-welcome, v.v.
#
{ ... }:

{
  nixpkgs.overlays = [
    (final: prev: {
      bamos-branding = final.callPackage ../../pkgs/bamos-branding { };
      bam-welcome = final.callPackage ../../pkgs/bam-welcome { };
    })
  ];
}
