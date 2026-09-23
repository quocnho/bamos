# Description: Âm thanh PipeWire stack aggregator (< 40 dòng)
# Tham khảo module pipewire.nix của GLF-OS
{ config, lib, ... }:

let
  cfg = config.my.audio;
in
{
  imports = [
    ./low-latency.nix
    ./noise-suppression.nix
    ./codec-heal.nix
  ];

  options.my.audio = {
    enable = lib.mkEnableOption "audio stack (PipeWire + noise suppression)";
  };

  config = lib.mkIf cfg.enable {
    # Quyền realtime scheduling cho audio
    security.rtkit.enable = true;

    services.pipewire = {
      enable = true;
      pulse.enable = true;
      jack.enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
    };
  };
}
