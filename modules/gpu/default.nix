# Description: GPU aggregator (Nvidia PRIME offload + RTD3 power management) (< 50 dòng)
{ config, lib, ... }:

let
  cfg = config.my.gpu;
in
{
  imports = [
    ./intel.nix
  ];

  options.my.gpu = {
    enable = lib.mkEnableOption "GPU config (NVIDIA + Intel)";

    intelBusId = lib.mkOption {
      type = lib.types.str;
      description = "Bus ID của iGPU Intel (lấy từ lspci).";
    };

    nvidiaBusId = lib.mkOption {
      type = lib.types.str;
      description = "Bus ID của GPU NVIDIA (lấy từ lspci).";
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.config.allowUnfree = true;
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.nvidia = {
      open = true;
      nvidiaSettings = true;
      modesetting.enable = true;
      powerManagement.enable = true;
      powerManagement.finegrained = true;

      prime = {
        offload.enable = true;
        offload.enableOffloadCmd = true;
        intelBusId = cfg.intelBusId;
        nvidiaBusId = cfg.nvidiaBusId;
      };
    };

    boot.blacklistedKernelModules = [
      "nouveau"
      "nova_core"
    ];
    environment.variables.__GL_SHADER_DISK_CACHE_SIZE = "12000000000";
  };
}
