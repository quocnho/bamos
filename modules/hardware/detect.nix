# modules/hardware/detect.nix
# Auto-detect hardware: GPU, PCI bus IDs, kernel modules
# Reads script from pkgs/bamos-detect-hardware.sh (avoids Nix $ interpolation issues)
#
{ config, lib, pkgs, ... }:
let
  detectScript = pkgs.writeScriptBin "bamos-detect-hardware" (
    builtins.readFile ../../pkgs/bamos-detect-hardware.sh
  );
in
{
  options.bamos.hardware = {
    detect = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable hardware detection: provides bamos-detect-hardware command";
    };
    dir = lib.mkOption {
      type = lib.types.str;
      default = "/etc/bamos";
      description = "Directory for auto-detected hardware configs";
    };
  };

  config = lib.mkIf config.bamos.hardware.detect {
    environment.systemPackages = [ detectScript ];
  };
}
