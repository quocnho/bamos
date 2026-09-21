# Quản lý năng lượng: suspend (deep/S3) + TLP + đánh thức bằng bàn phím + đồng bộ RTC.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.power;
in
{
  options.my.power = {
    enable = lib.mkEnableOption "power management (s2idle + TLP)";
  };

  config = lib.mkIf cfg.enable {
    # ==== Suspend DEEP (S3) — qua kernel param, KHÔNG qua sleep.conf ====
    # `mem_sleep_default=deep` → kernel chọn deep thay vì s2idle.
    # LÝ DO: máy bị chuỗi lỗi HDA khi s2idle — codec analog "No response from
    # codec" sau thức dậy → audio mất / shutdown TREO không tắt hẳn (máy chỉ
    # tắt màn, nút nguồn sáng, drain pin qua đêm → mất RTC → BIOS về 1970 GMT;
    # xem journalctl -b -2 lúc 16:37-16:46: azx_get_response timeout spam).
    # deep/S3 đã xác nhận máy HỖ TRỢ (/sys/power/mem_sleep: s2idle + deep).
    # Nếu thức dậy chậm/vấn đề: đổi lại "s2idle".
    # ⚠️ KHÔNG dùng systemd.sleep.settings nữa: `SuspendMode=` đã bị REMOVE
    # trong systemd 261+ → gây lỗi "Requested suspend operation not supported".
    boot.kernelParams = [ "mem_sleep_default=deep" ];

    services.power-profiles-daemon.enable = false;
    services.tlp.enable = true;
    services.logind.settings.Login.HandleLidSwitch = "suspend";

    # Intel Thermal Daemon: quản nhiệt chủ động → giảm throttling đột ngột,
    # giữ hiệu năng ổn định và hiệu quả năng lượng tốt hơn khi tải.
    services.thermald.enable = true;

    # ==== TLP 1.10.2 (bản mới nhất — upstream & nixpkgs đều là bản này) ====
    # Defaults của TLP 1.10.2 đã tối ưu sẵn cho máy này (WIFI_PWR,
    # SOUND_POWER_SAVE, RUNTIME_PM on/auto, NMI_WATCHDOG=0, ...).
    # Bổ sung vài thứ riêng cho laptop LG này:
    services.tlp.settings = {
      # Battery care kiểu LG — tương đương "Battery Care Mode" trong
      # LG Control Center (Windows): chỉ sạc tới 80% để kéo dài tuổi thọ pin.
      # LG CHỈ hỗ trợ giá trị 80 hoặc 100, và KHÔNG có start threshold riêng.
      # TLP nhận diện tự động qua plugin `35-lg` + module kernel lg_laptop.
      STOP_CHARGE_THRESH_BAT0 = "100";

      # Ưu tiên PIN: EPP "power" khi chạy bằng pin (i5-10210U vẫn đủ mạnh
      # cho Firefox + devenv), "balance_performance" khi cắm sạc.
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
      CPU_BOOST_ON_BAT = 0;
      CPU_BOOST_ON_AC = 1;

      # Không cho TLP can thiệp runtime-PM vào driver NVIDIA — tránh xung đột
      # với hardware.nvidia.powerManagement (RTD3) trong modules/gpu.nix.
      # (Đây cũng là giá trị mặc định của TLP 1.10.2.)
      RUNTIME_PM_DRIVER_DENYLIST = "amdgpu mei_me nouveau nvidia xhci_hcd";

      # SOUND_POWER_SAVE=0 — tắt runtime-PM của HDA (snd_hda_intel): máy này
      # hay bị MẤT codec analog / Dummy Output sau boot & thức từ s2idle do
      # HDA runtime suspend không hồi phục ổn định. Hao pin không đáng kể.
      SOUND_POWER_SAVE = "0";
    };

    # Cho phép bàn phím USB (kể cả receiver không dây) đánh thức máy từ suspend.
    # Bật wakeup cho bàn phím HID (bInterfaceProtocol=01) — KHÔNG cho chuột (02).
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="usb", ATTR{bInterfaceClass}=="03", ATTR{bInterfaceProtocol}=="01", ATTR{power/wakeup}="enabled"
      ACTION=="add", SUBSYSTEM=="usb", ATTR{bDeviceClass}=="09", ATTR{power/wakeup}="enabled"
    '';

    # Nếu bàn phím vẫn lờ đờ sau khi thức, bỏ comment dòng dưới:
    # (Tắt USB autosuspend của TLP — tiêu tốn pin hơn một chút)
    # services.tlp.settings.USB_AUTOSUSPEND = "0";

    # ==== Đồng bộ RTC định kỳ (phòng khi shutdown bị treo / mất nguồn đột ngột) ====
    # Bình thường Linux ghi RTC khi shutdown sạch — nếu shutdown không hoàn tất,
    # RTC giữ giờ CŨ → boot sau giờ sai/Bios reset. Timer này ghi RTC mỗi 6h +
    # 5 phút sau boot (sau khi NTP đã đồng bộ), giúp hạn chế hậu quả.
    systemd.services."bamos-sync-rtc" = {
      description = "Đồng bộ giờ hệ thống xuống RTC (phòng mất nguồn)";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.util-linux}/bin/hwclock --systohc --utc";
      };
    };
    systemd.timers."bamos-sync-rtc" = {
      description = "Chạy đồng bộ RTC định kỳ";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5min";
        OnUnitActiveSec = "6h";
        Persistent = true;
      };
    };
  };
}
