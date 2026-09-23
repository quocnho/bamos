# Description: Cấu hình OBS Studio, NVENC helper & plugins
{ config, lib, pkgs, ... }:

let
  cfg = config.my.studio;
  hasNvidia = config.my.gpu.enable;

  obsNvenc = pkgs.writeShellScriptBin "obs-nvenc" ''
    exec nvidia-offload obs
  '';
in
{
  config = lib.mkIf (cfg.enable && cfg.obs.enable) {
    programs.obs-studio = {
      enable = true;
      enableVirtualCamera = cfg.obs.virtualCamera;
      plugins =
        (with pkgs.obs-studio-plugins; [
          obs-pipewire-audio-capture
          obs-vkcapture
          obs-composite-blur
        ])
        ++ lib.optionals cfg.obs.vaapi [ pkgs.obs-studio-plugins.obs-vaapi ];
    };

    programs.obs-studio.package = lib.mkIf hasNvidia (
      lib.mkForce (pkgs.obs-studio.override { cudaSupport = true; })
    );

    environment.systemPackages = lib.mkIf hasNvidia [ obsNvenc ];
  };
}
