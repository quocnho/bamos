# Description: Ứng dụng sáng tạo âm thanh, hình ảnh & video dựng phim
{ config, lib, pkgs, ... }:

let
  cfg = config.my.studio;
in
{
  config = lib.mkIf cfg.enable (
    lib.mkMerge [
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

      # TIỆN ÍCH HỆ THỐNG
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
