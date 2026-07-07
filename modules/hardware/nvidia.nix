# modules/hardware/nvidia.nix
# NVIDIA GPU configuration — professional setup cho laptop & desktop
#
# ═══════════════════════════════════════════════════════════════
# Cách dùng:
#   1. Tự động: hardware-configuration.nix (nixos-generate-config)
#      sẽ detect NVIDIA GPU và import module này
#
#   2. Thủ công: thêm vào configuration.nix
#      { imports = [ ../modules/hardware/nvidia.nix ]; }
#
#   3. Edition override: bamos.nvidia.mode = "sync" | "async" | "nvidia"
# ═══════════════════════════════════════════════════════════════
{ config, lib, pkgs, ... }:

let
  cfg = config.bamos.nvidia;
  # Tự động detect NVIDIA GPU từ PCI hardware
  hasNvidiaGPU = builtins.any (pci: lib.hasPrefix "10de" (pci.vendor or "")) (builtins.attrValues config.hardware.pciDevices or { });
in
{
  options.bamos.nvidia = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Bật NVIDIA driver (tự động detect từ PCI nếu có)";
    };

    open = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Sử dụng NVIDIA open-source kernel module (Turing+). True cho driver mới, false cho driver đóng";
    };

    mode = lib.mkOption {
      type = lib.types.enum [ "sync" "async" "nvidia" ];
      default = "nvidia";
      description = ''
        Chế độ render cho laptop Optimus/PRIME:
        - "sync":   Đồng bộ — ổn định nhất, dùng cho desktop/ổn định
        - "async":  Bất đồng bộ — nhanh hơn, dùng cho gaming
        - "nvidia": Chỉ dùng GPU NVIDIA — hiệu năng cao nhất, dùng cho gaming/studio
      '';
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = config.boot.kernelPackages.nvidiaPackages.stable;
      description = "NVIDIA driver package (production/beta/latest)";
    };

    prime = {
      intelBusId = lib.mkOption {
        type = lib.types.str;
        default = "PCI:0:2:0";
        description = "Intel iGPU bus ID. Chạy 'bamos-detect-gpu' để phát hiện tự động";
      };
      nvidiaBusId = lib.mkOption {
        type = lib.types.str;
        default = "PCI:1:0:0";
        description = "NVIDIA dGPU bus ID. Chạy 'bamos-detect-gpu' để phát hiện tự động";
      };
      allowExternalGpu = lib.mkEnableOption "Allow external GPU (eGPU) via Thunderbolt/USB4";
      reverseSync.enable = lib.mkEnableOption "Reverse PRIME sync (Intel iGPU → NVIDIA dGPU)";
    };

    powerManagement = {
      enable = lib.mkEnableOption "NVIDIA power management (Fine-grained)";
      finegrained = lib.mkEnableOption "Fine-grained power management (RTD3)";
    };
  };

  config = lib.mkIf cfg.enable {
    # ═══════════════════════════════════════════════════════
    # NVIDIA DRIVERS
    # ═══════════════════════════════════════════════════════
    # BẮT BUỘC: khai báo driver NVIDIA để NixOS kích hoạt hardware.video.nvidia module
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.nvidia = {
      package = cfg.package;

      # Modesetting: bắt buộc cho Wayland
      modesetting.enable = true;

      # NVDEC/NVENC: tăng tốc video encode/decode
      nvidiaSettings = true;

      # Open kernel module (Turing RTX 2000+ hoặc newer)
      open = cfg.open;

      # ═══════════════════════════════════════════════════
      # PRIME (Optimus) cho laptop — bus IDs luôn cần dù mode nào
      # Chạy 'bamos-detect-gpu' để lấy bus IDs chính xác
      # ═══════════════════════════════════════════════════
      prime = {
        # Sync mode: cả iGPU và dGPU cùng chạy (ổn định)
        sync = lib.mkIf (cfg.mode == "sync") {
          enable = true;
        };

        # Offload mode (nvidia): chỉ dùng GPU rời
        offload = lib.mkIf (cfg.mode == "nvidia") {
          enable = true;
          enableOffloadCmd = true;
        };

        allowExternalGpu = cfg.prime.allowExternalGpu;
        reverseSync.enable = cfg.prime.reverseSync.enable;

        # Bus IDs
        intelBusId = cfg.prime.intelBusId;
        nvidiaBusId = cfg.prime.nvidiaBusId;
      };

      # ═══════════════════════════════════════════════════
      # Power Management
      # ═══════════════════════════════════════════════════
      powerManagement = {
        enable = cfg.powerManagement.enable;
        finegrained = cfg.powerManagement.finegrained;
      };
    };

    # ═══════════════════════════════════════════════════
    # BOOT: blacklist nouveau + load NVIDIA modules sớm
    # ═══════════════════════════════════════════════════
    boot = {
      blacklistedKernelModules = [ "nouveau" ];
      kernelModules = [ "nvidia_drm" "nvidia_modeset" "nvidia_uvm" "nvidia" ];
      kernelParams = [
        "nvidia_drm.fbdev=1"
        "nvidia_drm.modeset=1"
      ];
    };

    # ═══════════════════════════════════════════════════
    # SERVICES: enable udev rules + power management
    # ═══════════════════════════════════════════════════
    services.udev.extraRules = ''
      # NVIDIA power management (RTD3)
      ACTION=="add" DEVPATH=="/bus/pci/drivers/nvidia" SUBSYSTEM=="drivers" ATTR{remove}="1"
    '';

    # ═══════════════════════════════════════════════════
    # ENVIRONMENT: CUDA + Vulkan + OpenGL
    # ═══════════════════════════════════════════════════
    environment.sessionVariables = {
      __GL_VRR_ALLOWED = "1"; # Adaptive Sync / G-Sync
      __GL_SHADER_DISK_CACHE_SIZE = "1073741824"; # 1GB shader cache
      __GL_SHADER_DISK_CACHE_SKIP_CLEANUP = "1"; # Keep shader cache
    };

    environment.systemPackages = with pkgs; [
      nvidia-vaapi-driver # VA-API video acceleration via NVIDIA
      vulkan-loader
      vulkan-tools # vulkaninfo
      libva
      libva-utils # vainfo
    ];

    # ═══════════════════════════════════════════════════
    # HARDWARE: iGPU early KMS (cho Intel hybrid)
    # ═══════════════════════════════════════════════════
    boot.initrd.kernelModules = lib.mkIf (cfg.mode != "nvidia") [
      "i915" # Intel integrated GPU
    ];
  };
}
