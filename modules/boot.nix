# Bootloader, kernel & Plymouth (màn hình splash khi boot).
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.boot;
in
{
  options.my.boot = {
    enable = lib.mkEnableOption "bootloader & kernel (systemd-boot, Plymouth)";

    kernel = lib.mkOption {
      type = lib.types.enum [
        "default"
        "zen"
        "latest"
      ];
      default = "latest";
      description = ''
        Kernel cho máy. So sánh chi tiết ở phần config bên dưới.
        - "default": kernel mặc định nixpkgs (6.18) — ổn định, tiết kiệm pin.
        - "zen":      kernel desktop (7.1 + patch zen) — mượt khi đa nhiệm.
        - "latest":   kernel mới nhất mainline (7.2) — không khuyến nghị.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    boot.loader.systemd-boot.enable = true;
    boot.loader.systemd-boot.configurationLimit = 10;
    boot.loader.efi.canTouchEfiVariables = true;

    # ==== KERNEL — phân tích chuyên sâu cho máy này (CometLake + GTX 1650) ====
    #
    # SO SÁNH (version theo nixpkgs đang lock — kiểm tra lại bằng:
    #   nix eval .#nixosConfigurations.lg.config.boot.kernelPackages.kernel.version)
    #
    # ▸ "default" — linuxPackages (6.18.48): kernel MẶC ĐỊNH nixpkgs.
    #   + Ổn định bậc nhất, đã "ngấm" lâu — ít regression.
    #   + Hiệu quả pin tốt nhất (C-states, intel_idle, EEVDF chín muồi).
    #   − Cảm giác tương tác ở mức "chuẩn" — không tối ưu cho desktop đa nhiệm.
    #
    # ▸ "zen" — linuxPackages_zen (7.1.10): kernel MẶC ĐỊNH của dự án Zen
    #   (patch desktop dựa trên mainline 7.1, cùng team đứng sau linux-cachyos).
    #   + Ưu tiên PHẢN HỒI NHANH: HZ=1000, scheduler EEVDF chỉnh cho desktop,
    #     preemption tốt hơn → cảm giác "mượt", ít giật khi nhiều app cùng lúc.
    #   + NVIDIA hoàn toàn tương thích (nixpkgs build driver cho từng kernelPackages
    #     — phiên bản driver GIỐNG HỆT ở mọi kernel: stable 595.99.02).
    #   − Hao pin nhẹ hơn kernel default (vài %).
    #   − Vẫn là kernel 7.x "trẻ" hơn 6.18 — nhưng đã là bản stable.
    #
    # ▸ "latest" — linuxPackages_latest (7.2.2): mainline MỚI NHẤT.
    #   + Không lợi ích gì cho CPU 2019; nixpkgs-unstable cập nhật liên tục
    #     → phải rebuild kernel + driver NVIDIA mỗi tuần, rủi ro regression.
    #   − KHÔNG khuyến nghị cho máy chính.
    #
    # KHUYẾN NGHỊ cho LG (work + OBS + đa nhiệm): "zen" nếu ưu tiên mượt mà,
    # "default" nếu ưu tiên pin/ổn định tuyệt đối. Muốn thử: đổi 1 dòng +
    # `bam boot` rồi chọn generation ở boot menu — rollback dễ dàng.
    # (mkDefault để máy khác có thể override theo ý riêng.)
    boot.kernelPackages = lib.mkDefault (
      if cfg.kernel == "zen" then
        pkgs.linuxPackages_zen
      else if cfg.kernel == "latest" then
        pkgs.linuxPackages_latest
      else
        pkgs.linuxPackages
    );

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
