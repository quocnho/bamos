# Description: Cấu hình Intel iGPU, VAAPI và i915 initrd module
{ pkgs, ... }:

{
  boot.initrd.kernelModules = [ "i915" ];

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      libvdpau-va-gl
    ];
  };

  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";
}
