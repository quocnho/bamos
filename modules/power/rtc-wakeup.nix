# Description: Đồng bộ đồng hồ phần cứng RTC và udev rules đánh thức bàn phím USB
{ pkgs, ... }:

{
  # Cho phép bàn phím USB đánh thức máy từ suspend
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{bInterfaceClass}=="03", ATTR{bInterfaceProtocol}=="01", ATTR{power/wakeup}="enabled"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{bDeviceClass}=="09", ATTR{power/wakeup}="enabled"
  '';

  # Đồng bộ RTC định kỳ
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
}
