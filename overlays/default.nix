# BamOS NixOS overlays.
# Exposes custom packages so they're available as pkgs.* in NixOS modules.

{ ... }:

{
  # Default overlay — adds BamOS custom packages to nixpkgs
  default = final: prev: {
    bamos-branding = final.callPackage ../pkgs/bamos-branding { };
  };
}
