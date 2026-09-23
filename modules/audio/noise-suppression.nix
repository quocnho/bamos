# Description: Mic ảo lọc ồn PipeWire bằng rnnoise
{ pkgs, ... }:

{
  services.pipewire = {
    extraConfig.pipewire."99-noise-suppression" = {
      "context.modules" = [
        {
          name = "libpipewire-module-filter-chain";
          flags = [ "nofail" ];
          args = {
            "node.description" = "Noise Canceling Source";
            "media.name" = "Noise Canceling Source";
            "filter.graph" = {
              nodes = [
                {
                  type = "ladspa";
                  name = "rnnoise";
                  plugin = "librnnoise_ladspa";
                  label = "noise_suppressor_stereo";
                  control = {
                    "VAD Threshold (%)" = 50.0;
                  };
                }
              ];
            };
            "capture.props" = {
              "node.name" = "effect_input.rnnoise";
              "node.passive" = true;
              "audio.rate" = 48000;
              "audio.position" = [
                "FL"
                "FR"
              ];
            };
            "playback.props" = {
              "node.name" = "rnnoise_source";
              "node.description" = "Noise Canceling Source";
              "media.class" = "Audio/Source";
              "audio.rate" = 48000;
              "audio.position" = [
                "FL"
                "FR"
              ];
            };
          };
        }
      ];
    };

    extraLadspaPackages = [ pkgs.rnnoise-plugin.ladspa ];
  };
}
