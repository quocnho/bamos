# Description: Cấu hình PipeWire low-latency (48 kHz, quantum 256 ~5.3ms)
{ ... }:

{
  services.pipewire = {
    extraConfig.pipewire."92-low-latency" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.quantum" = 256;
        "default.clock.min-quantum" = 256;
        "default.clock.max-quantum" = 256;
      };
    };

    # WirePlumber: tắt monitor libcamera (tránh PipeWire giữ webcam)
    wireplumber.extraConfig."10-disable-camera" = {
      "wireplumber.profiles" = {
        main = {
          "monitor.libcamera" = "disabled";
        };
      };
    };
  };
}
