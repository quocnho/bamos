# pkgs/bam-cli/default.nix
# BamOS CLI — built from pkgs/bam.sh with path substitution
{ lib, pkgs, buildFHSEnvBubblewrap, ... }:

let
  fhsEnv = buildFHSEnvBubblewrap {
    name = "bam-fhs";
    targetPkgs = pkgs: with pkgs; [ bashInteractive coreutils gnused gawk findutils util-linux ];
    runScript = "";
  };

  bamScript = pkgs.writeShellScriptBin "bam" (
    builtins.replaceStrings
      [ "@fhsEnv@" "@inxi@" "@lspci@" ]
      [ "${fhsEnv}/bin/bam-fhs" "${pkgs.inxi}/bin/inxi" "${pkgs.pciutils}/bin/lspci" ]
      (builtins.readFile ../../pkgs/bam.sh)
  );
in
bamScript
