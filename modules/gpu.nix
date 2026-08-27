# Đồ họa: NVIDIA + Intel — tham khảo module `nvidia.nix` của GLF-OS
# (framagit.org/gaming-linux-fr/glf-os).
#
# Điểm mấu chốt học từ GLF-OS:
#  - `open = true`: open kernel modules, NVIDIA khuyến nghị cho Turing+
#    từ driver R560. GPU ở đây là GTX 1650 (TU117, kiến trúc Turing).
#  - `powerManagement.enable`: bật NVreg_PreserveVideoMemoryAllocations=1
#    và các bước suspend/resume → VRAM được giữ/khôi phục khi suspend,
#    tránh màn hình đen / GPU mất trạng thái khi thức dậy. Driver >= 595
#    với open modules sẽ tự dùng kernel suspend notifiers.
#  - Blacklist `nouveau` + `nova_core` để không xung đột driver.
#  - Tăng shader disk cache cho game/ứng dụng GL.
#
# KHÔNG khai báo tay systemd-services nvidia-suspend/resume như GLF-OS:
# nixpkgs (revision đang lock) đã tự sinh chúng qua `powerManagement.enable`
# → khai báo thêm sẽ bị lỗi duplicate definition.
{ config, lib, pkgs, ... }:

let
  cfg = config.my.gpu;
in
{
  options.my.gpu = {
    enable = lib.mkEnableOption "GPU config (NVIDIA + Intel)";

    intelBusId = lib.mkOption {
      type = lib.types.str;
      description = "Bus ID của iGPU Intel (lấy từ lspci).";
    };

    nvidiaBusId = lib.mkOption {
      type = lib.types.str;
      description = "Bus ID của GPU NVIDIA (lấy từ lspci).";
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.config.allowUnfree = true; # driver NVIDIA là unfree

    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.nvidia = {
      # Open kernel modules (Turing+, khuyến nghị R560+).
      # Nếu gặp lỗi bất thường, đổi về `open = false` rồi rebuild.
      open = true;
      nvidiaSettings = true;
      modesetting.enable = true;

      # Quản lý năng lượng: PreserveVideoMemoryAllocations + suspend/resume.
      powerManagement.enable = true;

      # ==== RTD3 (fine-grained power management) — tối ưu PIN ====
      # Cho phép dGPU TẮT HẲN (runtime suspend, ~0W) khi không có ứng dụng
      # nào dùng nó. Trước đây dGPU luôn "active" và ngốn ~2.7W liên tục
      # (đã đo thực tế). Yêu cầu prime.offload.enable (đã bật ✓).
      # Lưu ý: màn hình ngoài cắm HDMI khi dGPU đang ngủ sẽ đánh thức nó
      # (hoạt động bình thường); nếu gặp vấn đề, đổi về `false`.
      powerManagement.finegrained = true;

      prime = {
        # PRIME render offload: chạy ứng dụng trên dGPU bằng
        # `nvidia-offload <lệnh>`.
        offload.enable = true;
        offload.enableOffloadCmd = true;
        intelBusId = cfg.intelBusId;
        nvidiaBusId = cfg.nvidiaBusId;
      };
    };

    # Đẩy i915 vào initrd để Plymouth có framebuffer sớm khi boot
    # (giống module `intel.nix` của GLF-OS).
    boot.initrd.kernelModules = [ "i915" ];

    # Chặn driver kernel mã nguồn mở khác để không xung đột với driver NVIDIA.
    boot.blacklistedKernelModules = [ "nouveau" "nova_core" ];

    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [ intel-media-driver libvdpau-va-gl ];
    };
    environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";

    # Shader disk cache lớn hơn (GLF-OS đặt 12 GB) — chỉ là giới hạn tối đa,
    # không chiếm chỗ cho tới khi thật sự cần.
    environment.variables.__GL_SHADER_DISK_CACHE_SIZE = "12000000000";
  };
}
