# Quản lý năng lượng: suspend nông (s2idle) + TLP + đánh thức bằng bàn phím.
{ config, lib, ... }:

let
  cfg = config.my.power;
in
{
  options.my.power = {
    enable = lib.mkEnableOption "power management (s2idle + TLP)";
  };

  config = lib.mkIf cfg.enable {
    # ==== Suspend nông (s2idle) — qua kernel param, KHÔNG qua sleep.conf ====
    # `mem_sleep_default=s2idle` → kernel chọn s2idle làm mặc định cho "mem".
    # ⚠️ KHÔNG dùng systemd.sleep.settings nữa: `SuspendMode=` đã bị REMOVE
    # trong systemd 261+ → gây lỗi "Requested suspend operation not
    # supported" → gấp nắp không sleep (chỉ tắt màn hình). Đã xác nhận trong
    # journalctl. Kernel param tự đảm nhiệm việc chọn s2idle.
    boot.kernelParams = [ "mem_sleep_default=s2idle" ];

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
      STOP_CHARGE_THRESH_BAT0 = "80";

      # Ưu tiên PIN: EPP "power" khi chạy bằng pin (i5-10210U vẫn đủ mạnh
      # cho Firefox + devenv). Nếu thấy máy ì, đổi lại "balance_power".
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

      # Không cho TLP can thiệp runtime-PM vào driver NVIDIA — tránh xung đột
      # với hardware.nvidia.powerManagement (RTD3) trong modules/gpu.nix.
      # (Đây cũng là giá trị mặc định của TLP 1.10.2.)
      RUNTIME_PM_DRIVER_DENYLIST = "amdgpu mei_me nouveau nvidia xhci_hcd";
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
  };
}
