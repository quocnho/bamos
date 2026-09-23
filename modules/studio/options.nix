# Description: Định nghĩa các options cho module Studio (< 55 dòng)
{ lib, ... }:

{
  options.my.studio = {
    enable = lib.mkEnableOption "studio (ghi hình/livestream OBS + công cụ sáng tạo)";

    obs = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "OBS Studio: ghi hình + livestream.";
      };
      virtualCamera = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Virtual camera (v4l2loopback).";
      };
      vaapi = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Plugin obs-vaapi encode bằng iGPU Intel.";
      };
    };

    davinciResolve = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "DaVinci Resolve.";
      };
      studio = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Dùng bản DaVinci Resolve STUDIO.";
      };
    };

    kdenlive = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Kdenlive NLE.";
    };

    gimp = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "GIMP chỉnh sửa ảnh.";
    };

    audacity = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Audacity ghi/chỉnh âm thanh.";
    };

    reaper = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "REAPER DAW chuyên nghiệp.";
    };

    fonts = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Font sáng tạo (overlay OBS, thumbnail).";
    };
  };
}
