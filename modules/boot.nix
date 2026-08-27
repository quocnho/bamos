# Bootloader, kernel & Plymouth (màn hình splash khi boot).
{ config, lib, pkgs, ... }:

let
  cfg = config.my.boot;
in
{
  options.my.boot = {
    enable = lib.mkEnableOption "bootloader & kernel (systemd-boot, Plymouth)";
  };

  config = lib.mkIf cfg.enable {
    boot.loader.systemd-boot.enable = true;
    boot.loader.systemd-boot.configurationLimit = 10;
    boot.loader.efi.canTouchEfiVariables = true;

    # ==== KERNEL — phân tích chuyên sâu cho máy này (CometLake i5-10210U) ====
    # `linuxPackages` (6.18): kernel MẶC ĐỊNH của nixpkgs — lựa chọn tối ưu:
    #  - Ổn định: đã "ngấm" ~9 tháng kể từ khi ra mắt → ít regression
    #  - Hiệu quả pin: quản lý năng lượng (C-states, intel_idle, EEVDF) chín muồi
    #  - NVIDIA tương thích bền (nixpkgs build driver cho từng kernelPackages)
    #  - CPU CometLake (2019) được hỗ trợ hoàn hảo từ kernel 5.x — kernel mới
    #    hơn KHÔNG mang lại hiệu năng đáng kể cho máy này
    #
    # So sánh các lựa chọn (rev đang lock):
    #  - linuxPackages_latest (7.2): mới nhất → rủi ro regression mỗi lần update
    #    nixpkgs, lợi ích với CPU cũ gần như bằng 0. KHÔNG khuyến nghị.
    #  - linuxPackages_zen (7.1): patch desktop (scheduler ưu tiên phản hồi) →
    #    cảm giác "smooth" hơn chút khi chạy đa nhiệm, nhưng hao pin hơn nhẹ.
    #    Chỉ đổi sang đây nếu bạn muốn tối ưu responsiveness thay vì pin.
    #  - XanMod: lợi ích thêm không đáng so với Zen, thời gian build lâu.
    boot.kernelPackages = pkgs.linuxPackages;

    # Tắt chữ chạy khi boot, bật splash (Plymouth)
    boot.plymouth.enable = true;
    boot.consoleLogLevel = 0;
    boot.initrd.verbose = false;
    boot.kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "loglevel=3"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
    ];
  };
}
