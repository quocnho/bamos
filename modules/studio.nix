# Description: STUDIO (edition studio-pro) — ghi hình + livestream bằng OBS + công cụ sáng tạo
# Bật: my.studio.enable = true; (hosts/lg.nix)
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.studio;
  hasNvidia = config.my.gpu.enable;

  creatorFonts = import ./studio/fonts.nix { inherit pkgs; };

  obsNvenc = pkgs.writeShellScriptBin "obs-nvenc" ''
    exec nvidia-offload obs
  '';
in
{
  options.my.studio = {
    enable = lib.mkEnableOption "studio (ghi hình/livestream OBS + công cụ sáng tạo — GLF-OS studio-pro)";

    obs = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "OBS Studio: ghi hình + livestream (lõi của studio).";
      };
      virtualCamera = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Virtual camera (v4l2loopback) — dùng OBS làm webcam ảo.";
      };
      vaapi = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Plugin obs-vaapi (encode bằng iGPU Intel — tiết kiệm pin).";
      };
    };

    davinciResolve = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "DaVinci Resolve (NLE chuyên nghiệp).";
      };
      studio = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Dùng bản DaVinci Resolve STUDIO (cần license).";
      };
    };

    kdenlive = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Kdenlive — NLE mã nguồn mở, nhẹ hơn Resolve (dự phòng).";
    };

    gimp = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "GIMP — làm thumbnail, ảnh overlay, chỉnh ảnh.";
    };

    audacity = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Audacity — ghi/chỉnh âm thanh.";
    };

    reaper = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "REAPER — DAW chuyên nghiệp (unfree) + bộ hiệu ứng Calf.";
    };

    fonts = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Font sáng tạo (overlay OBS, thumbnail, UI dựng phim).";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      # OBS STUDIO
      (lib.mkIf cfg.obs.enable {
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
      })

      # DỰNG PHIM
      (lib.mkIf cfg.davinciResolve.enable {
        environment.systemPackages = [
          (if cfg.davinciResolve.studio then pkgs.davinci-resolve-studio else pkgs.davinci-resolve)
          pkgs.clinfo
        ];
        hardware.graphics.extraPackages = [ pkgs.intel-compute-runtime ];
      })
      (lib.mkIf cfg.kdenlive {
        environment.systemPackages = [ pkgs.kdePackages.kdenlive ];
      })

      # ẢNH & ÂM THANH
      (lib.mkIf cfg.gimp {
        environment.systemPackages = [ pkgs.gimp3-with-plugins ];
      })
      (lib.mkIf cfg.audacity {
        environment.systemPackages = [ pkgs.audacity ];
      })
      (lib.mkIf cfg.reaper {
        environment.systemPackages = [
          pkgs.reaper
          pkgs.calf
        ];
      })

      # FONTS SÁNG TẠO
      (lib.mkIf cfg.fonts {
        fonts.packages = creatorFonts;
      })

      # CÔNG CỤ & MÔI TRƯỜNG
      {
        environment.systemPackages = with pkgs; [
          libva-utils
          intel-gpu-tools
          pavucontrol
        ];
      }
    ]
  );
}
