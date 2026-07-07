# modules/hardware/power-management.nix
# Quản lý năng lượng BamOS — tuned + kernel + hardware tuning
#
# Case study: LG Gram (i5-10210U, GTX 1650, NVMe, 15GB RAM)
#   ├── CPU: 8 cores, 1.6-4.2 GHz, governor động theo PPD profile
#   ├── GPU: Intel UHD (iGPU) + NVIDIA GTX 1650 (dGPU, offload)
#   ├── Disk: NVMe (I/O scheduler = none)
#   └── Audio: power_save = 10s
#
# tuned profiles:
#   desktop               → Desktop (sched_autogroup)
#   throughput-performance → Build code
#   latency-performance    → Gaming/Studio (độ trễ thấp)
#   powersave              → Tiết kiệm pin tối đa
#   laptop-battery-powersave → Laptop khi không cắm sạc
#
{ config, lib, pkgs, ... }:

let
  cfg = config.bamos.power-management;
in
{
  options.bamos.power-management = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Bật tuned + kernel power tuning";
    };

    profile = lib.mkOption {
      type = lib.types.enum [
        "balanced"
        "desktop"
        "throughput-performance"
        "latency-performance"
        "powersave"
        "laptop-battery-powersave"
        "laptop-ac-powersave"
        "virtual-guest"
      ];
      default = "balanced";
      description = "tuned profile mặc định";
    };

    ppdSupport = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "PPD bridge — GNOME/KDE chuyển profile được";
    };

    dynamicTuning = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Tự động điều chỉnh theo CPU load (thay auto-cpufreq)";
    };

    batteryOptimized = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Tối ưu pin laptop (ASPM powersupersave, runtime PM, network)";
    };

    enableSwap = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Tạo swap file (hỗ trợ hibernate)";
    };

    swapSize = lib.mkOption {
      type = lib.types.int;
      default = 16384;
      description = "Dung lượng swap file (MB). Mặc định 16384 = 16GB";
    };
  };

  config = lib.mkIf cfg.enable {
    # ═══════════════════════════════════════════════════════
    # 1. TẮT service xung đột
    # ═══════════════════════════════════════════════════════
    services.power-profiles-daemon.enable = lib.mkForce false;
    services.tlp.enable = lib.mkForce false;

    # ═══════════════════════════════════════════════════════
    # 2. tuned
    # ═══════════════════════════════════════════════════════
    services.tuned = {
      enable = true;
      ppdSupport = cfg.ppdSupport;

      settings = {
        daemon = true;
        dynamic_tuning = cfg.dynamicTuning;
        sleep_interval = 1;
        update_interval = 10;
        default_instance_priority = 0;
      };

      ppdSettings = lib.mkIf cfg.ppdSupport {
        main = {
          default = "balanced";
          battery_detection = cfg.batteryOptimized;
        };
        profiles = {
          power-saver = "powersave";
          balanced = cfg.profile;
          performance = "throughput-performance";
        };
        battery = lib.mkIf cfg.batteryOptimized {
          balanced = "laptop-battery-powersave";
        };
      };
    };

    services.upower.enable = lib.mkIf cfg.ppdSupport true;
    security.polkit.enable = true;

    # ═══════════════════════════════════════════════════════
    # 3. Kernel tuning (dựa trên case study LG Gram)
    # ═══════════════════════════════════════════════════════
    boot = {
      kernelParams = [
        # Audio: power saving sau 10s idle
        "snd-hda-intel.power_save=10"
      ] ++ lib.optionals cfg.batteryOptimized [
        # PCIe ASPM: tiết kiệm pin tối đa
        "pcie_aspm.policy=powersupersave"
        # Network: WiFi power saving
        "iwlwifi.power_save=1"
        # Intel P-state: on battery
        "intel_idle.max_cstate=4"
      ];

      kernelModules = lib.optionals cfg.batteryOptimized [
        "iTCO_wdt" # Watchdog timer (tắt khi không dùng)
      ];

      blacklistedKernelModules = lib.optionals cfg.batteryOptimized [
        "pcspkr" # Tắt loa PC speaker (tiết kiệm năng lượng không đáng kể)
      ];
    };

    # ═══════════════════════════════════════════════════════
    # 4. CPU frequency scaling — Intel P-state + energy_perf_bias
    # ═══════════════════════════════════════════════════════
    powerManagement = {
      cpuFreqGovernor = lib.mkDefault "powersave";
      cpufreq.max = lib.mkDefault 4200000; # 4.2 GHz (boost)
      cpufreq.min = lib.mkDefault 400000; # 400 MHz (tiết kiệm)
    };

    # ═══════════════════════════════════════════════════════
    # 5. Audio power saving
    # ═══════════════════════════════════════════════════════
    services.pulseaudio.daemon.config = {
      default-fragments = 4;
      default-fragment-size-msec = 25;
    };

    # ═══════════════════════════════════════════════════════
    # 6. Network power saving (laptop battery)
    # ═══════════════════════════════════════════════════════
    networking = lib.mkIf cfg.batteryOptimized {
      networkmanager.wifi.powersave = true;
      firewall.enable = lib.mkDefault true;
    };

    # ═══════════════════════════════════════════════════════
    # 7. Runtime Power Management (PCI devices)
    # ═══════════════════════════════════════════════════════
    services.udev.extraRules = lib.mkIf cfg.batteryOptimized ''
      # PCI Runtime PM: cho phép PCI devices tự động sleep
      ACTION=="add", SUBSYSTEM=="pci", ATTR{power/control}="auto"
    '';

    # ═══════════════════════════════════════════════════════
    # 8. Swap file (optional — cho hibernate)
    # ═══════════════════════════════════════════════════════
    swapDevices = lib.mkIf cfg.enableSwap [{
      device = "/swapfile";
      size = cfg.swapSize;
    }];
  };
}
