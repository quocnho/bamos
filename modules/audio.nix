# Âm thanh: PipeWire + mic ảo khử tiếng ồn (rnnoise) + cấu hình low-latency.
# Tham khảo module `pipewire.nix` của GLF-OS
# (framagit.org/gaming-linux-fr/glf-os).
#
# Lưu ý: GNOME (qua gnome-remote-desktop) đã tự bật pipewire.enable — module
# này khai báo tường minh và bổ sung phần còn lại: rtkit, JACK/ALSA compat,
# low-latency, mic filter, và xử lý LADSPA_PATH đúng chuẩn nixpkgs >= 26.05.
{ config, lib, pkgs, ... }:

let
  cfg = config.my.audio;
in
{
  options.my.audio = {
    enable = lib.mkEnableOption "audio stack (PipeWire + noise suppression)";
  };

  config = lib.mkIf cfg.enable {
    # Quyền realtime scheduling cho audio (tránh rách tiếng khi tải nặng).
    security.rtkit.enable = true;

    services.pipewire = {
      enable = true;
      # Tương thích PulseAudio (mọi app GTK/Electron/web) + JACK (DAW,
      # phần mềm ghi âm như Ardour/Carla/Reaper).
      pulse.enable = true;
      jack.enable = true;
      alsa = {
        enable = true;
        support32Bit = true; # app 32-bit (game, Wine) dùng được ALSA
      };

      # ==== Low-latency (GLF-OS): 48 kHz, quantum 256 (~5.3 ms) ====
      # Cân bằng giữa độ trễ thấp và độ ổn định cho ghi âm/chơi game.
      extraConfig.pipewire."92-low-latency" = {
        "context.properties" = {
          "default.clock.rate" = 48000;
          "default.clock.quantum" = 256;
          "default.clock.min-quantum" = 256;
          "default.clock.max-quantum" = 256;
        };
      };

      # ==== Mic filter: khử tiếng ồn nền bằng rnnoise (GLF-OS) ====
      # Tạo nguồn mic ảo "Noise Canceling Source" (media.class Audio/Source).
      # Trong cài đặt âm thanh của app gọi video/ghi âm, chọn nguồn này thay
      # vì mic thật → tiếng ồn nền (quạt, bàn phím...) bị lọc trước khi tới app.
      extraConfig.pipewire."99-noise-suppression" = {
        "context.modules" = [{
          name = "libpipewire-module-filter-chain";
          # nofail: nếu plugin rnnoise không load được thì audio không sập
          # theo (tránh restart-loop của pipewire.service).
          flags = [ "nofail" ];
          args = {
            "node.description" = "Noise Canceling Source";
            "media.name" = "Noise Canceling Source";
            "filter.graph" = {
              nodes = [{
                type = "ladspa";
                name = "rnnoise";
                # Short-name: PipeWire 1.6 tìm qua LADSPA_PATH (set tự động
                # bởi extraLadspaPackages bên dưới). Path tuyệt đối vào store
                # sẽ bị lỗi "spa.filter-graph: can't load plugin".
                plugin = "librnnoise_ladspa";
                # Bản stereo — phải khớp 2 kênh FL/FR ở audio.position bên dưới.
                label = "noise_suppressor_stereo";
                control = { "VAD Threshold (%)" = 50.0; };
              }];
            };
            "capture.props" = {
              "node.name" = "effect_input.rnnoise";
              # passive: mic thật chỉ được mở khi có app đang dùng nguồn ảo.
              "node.passive" = true;
              "audio.rate" = 48000;
              "audio.position" = [ "FL" "FR" ];
            };
            "playback.props" = {
              "node.name" = "rnnoise_source";
              "node.description" = "Noise Canceling Source";
              "media.class" = "Audio/Source";
              "audio.rate" = 48000;
              "audio.position" = [ "FL" "FR" ];
            };
          };
        }];
      };

      # Đưa plugin rnnoise vào LADSPA_PATH của pipewire user service
      # (nixpkgs >= 26.05 tự xây env aggregate + export LADSPA_PATH).
      # Dùng `pkgs.rnnoise-plugin.ladspa` để package nằm cố định trong
      # closure hệ thống (không bị nix GC dọn mất).
      extraLadspaPackages = [ pkgs.rnnoise-plugin.ladspa ];
    };

    # WirePlumber: tắt monitor libcamera — webcam không bị PipeWire giữ làm
    # nguồn video (GLF-OS làm vậy để tránh xung đột camera).
    services.pipewire.wireplumber.extraConfig."10-disable-camera" = {
      "wireplumber.profiles" = {
        main = {
          "monitor.libcamera" = "disabled";
        };
      };
    };

    # GLF-OS còn thêm `usbcore.autosuspend=-1` để chống rách tiếng USB DAC —
    # KHÔNG áp dụng ở đây: laptop này dùng audio nội (snd_hda_intel), và tắt
    # autosuspend USB sẽ vô hiệu hóa tiết kiệm pin của TLP (modules/power.nix).
  };
}
