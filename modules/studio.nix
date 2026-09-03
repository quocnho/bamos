# STUDIO (edition studio-pro) — ghi hình + livestream bằng OBS + công cụ sáng tạo.
#
# Tham khảo sâu GLF-OS (framagit.org/gaming-linux-fr/glf-os, nhánh testing):
#   - modules/default/creation.nix            → wiring OBS/plugin + gia tốc encode
#   - modules/default/glf-features/catalog.nix → preset "studio-pro" = video-production
#     + streaming (+ office/media/photo/gaming) + font creator
#   - modules/default/{graphics,intel,nvidia}.nix → nền đồ họa + VAAPI/NVENC
#
# "studio-pro" của GLF = "studio" nhưng dùng DaVinci Resolve STUDIO. Phần lõi
# cho nhu cầu của LG (ghi hình + livestream OBS trên laptop Optimus Intel+NVIDIA):
#
#   1. OBS Studio + virtual camera + plugin bắt âm thanh PipeWire, game capture
#      (obs-vkcapture), hiệu ứng (composite-blur, move-transition).
#   2. Encode TỐI ƯU theo GPU của LG (GTX 1650 = Turing):
#        • NVENC (dGPU):   chạy OBS qua lệnh `obs-nvenc` (gói cài sẵn) → driver
#          NVIDIA + CUDA, encoder chuyên dụng, chất lượng cao, CPU rảnh.
#        • VAAPI (iGPU):   plugin obs-vaapi + intel-media-driver (iHD) — tiết
#          kiệm pin, đủ tốt cho 1080p; test bằng `vainfo`.
#        • x264 (CPU):     dự phòng khi không cần tiết kiệm.
#      (Lưu ý: dGPU tắt khi không dùng — RTD3 — nên lần đầu dùng NVENC, OBS có
#       thể mất vài giây "đánh thức" GPU. Nếu NVENC báo lỗi, chạy `obs-nvenc`.)
#   3. Công cụ hậu kỳ/overlay: GIMP (thumb/ảnh overlay), Audacity (âm thanh),
#      DaVinci Resolve / Kdenlive (dựng phim — tùy chọn), fonts sáng tạo.
#   4. Công cụ chẩn đoán đa phương tiện: vainfo, intel_gpu_top, clinfo...
#
# Bật:  my.studio.enable = true;   (hosts/lg.nix)
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.studio;

  # GPU NVIDIA có mặt? (host lg bật my.gpu = Optimus Intel + NVIDIA)
  hasNvidia = config.my.gpu.enable;

  # Fonts sáng tạo (nhóm "studioFonts" của GLF-OS — dùng cho OBS overlay,
  # thumbnail, UI dựng phim). Việt hóa: thêm tiếng Việt cần font nào thì
  # bổ sung ở đây.
  creatorFonts = with pkgs; [
    noto-fonts-color-emoji # emoji màu (overlay/chat)
    liberation_ttf # Arial/Times/Courier metric-compatible (văn bản tiêu chuẩn)
    fira-code # code (có sẵn BamOS qua assets.nix — giữ để chắc)
    roboto
    lato
    montserrat
    raleway
    oswald # chữ đậm kiểu poster/stream
    merriweather
    poppins
    source-sans-pro
    league-spartan
  ];

  # Wrapper chạy OBS trên dGPU NVIDIA (PRIME offload) → dùng được NVENC.
  # Không cần đăng nhập lại: chỉ cần chạy `obs-nvenc` thay cho `obs`.
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

    # Dựng phim: DaVinci Resolve (studio-pro dùng bản STUDIO — mở khóa mua
    # trong app; bản free "resolve" đủ dùng cho hầu hết). Mặc định TẮT vì
    # nặng; bật khi cần dựng phim thật sự.
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
      description = "REAPER — DAW chuyên nghiệp (unfree) + bộ hiệu ứng Calf (EQ/compressor cho audio stream).";
    };

    fonts = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Font sáng tạo (overlay OBS, thumbnail, UI dựng phim).";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      # ====================== OBS STUDIO ======================
      (lib.mkIf cfg.obs.enable {
        programs.obs-studio = {
          enable = true;
          enableVirtualCamera = cfg.obs.virtualCamera;
          # obs-vaapi thêm vào khi bật vaapi (iGPU Intel luôn có sẵn)
          plugins =
            (with pkgs.obs-studio-plugins; [
              obs-pipewire-audio-capture # bắt âm thanh ứng dụng qua PipeWire
              obs-vkcapture # game capture (Vulkan) — chạy game qua wrapper vkcapture
              obs-composite-blur # làm mờ nền (kiểu blur webcam/nền)
              obs-move-transition # transition chuyển cảnh mượt
            ])
            ++ lib.optionals cfg.obs.vaapi [ pkgs.obs-studio-plugins.obs-vaapi ];
        };

        # Máy có NVIDIA (lg = Optimus): build OBS với CUDA → encoder NVENC.
        # (obs-vaapi vẫn dùng được iGPU Intel song song.)
        programs.obs-studio.package = lib.mkIf hasNvidia (
          lib.mkForce (pkgs.obs-studio.override { cudaSupport = true; })
        );

        # Lệnh chạy OBS trên dGPU cho NVENC: `obs-nvenc`
        environment.systemPackages = lib.mkIf hasNvidia [ obsNvenc ];
      })

      # ====================== DỰNG PHIM ======================
      (lib.mkIf cfg.davinciResolve.enable {
        # studio-pro của GLF dùng bản STUDIO; bản free "resolve" đủ cho phần lớn nhu cầu.
        environment.systemPackages = [
          (if cfg.davinciResolve.studio then pkgs.davinci-resolve-studio else pkgs.davinci-resolve)
          pkgs.clinfo # kiểm tra OpenCL
        ];
        # OpenCL cho iGPU Intel (như GLF-OS intel.nix opencl.enable) — Resolve
        # chạy được trên iGPU khi dGPU tắt.
        hardware.graphics.extraPackages = [ pkgs.intel-compute-runtime ];
      })
      (lib.mkIf cfg.kdenlive {
        environment.systemPackages = [ pkgs.kdePackages.kdenlive ];
      })

      # ====================== ẢNH & ÂM THANH ======================
      (lib.mkIf cfg.gimp {
        environment.systemPackages = [ pkgs.gimp3-with-plugins ];
      })
      (lib.mkIf cfg.audacity {
        environment.systemPackages = [ pkgs.audacity ];
      })
      (lib.mkIf cfg.reaper {
        # REAPER + Calf Studio Gear (EQ/compressor... plugin LV2 cho DAW/stream)
        environment.systemPackages = [
          pkgs.reaper
          pkgs.calf
        ];
      })

      # ====================== FONTS SÁNG TẠO ======================
      (lib.mkIf cfg.fonts {
        fonts.packages = creatorFonts;
      })

      # ====================== CÔNG CỤ & MÔI TRƯỜNG ======================
      {
        # Chẩn đoán đa phương tiện + điều khiển âm lượng/routing khi livestream
        # (vainfo: kiểm tra VAAPI encode iGPU; intel_gpu_top: xem tải iGPU;
        #  pavucontrol: chỉnh volume/routing từng ứng dụng — dễ hơn GNOME Settings)
        environment.systemPackages = with pkgs; [
          libva-utils
          intel-gpu-tools
          pavucontrol
        ];
        # (Muốn xem graph routing PipeWire chi tiết: thêm pkgs.helvum)
      }
    ]
  );
}
