# Description: Tự phục hồi analog codec (ALC) sau boot nếu thiếu
{ pkgs, ... }:

{
  systemd.services.audio-codec-heal = {
    description = "Audio: tự reload HDA nếu thiếu codec analog sau boot";
    wantedBy = [ "multi-user.target" ];
    after = [
      "systemd-modules-load.service"
      "systemd-udevd.service"
    ];
    before = [ "display-manager.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = [
      pkgs.kmod
      pkgs.gnugrep
      pkgs.coreutils
    ];
    script = ''
      # Có card HDA không? Nếu không thì thôi (không phải máy này)
      if ! grep -q 'HDA Intel PCH' /proc/asound/cards; then
        exit 0
      fi
      # Đã có pcm loa/tai nghe/mic analog? → OK
      if grep -qiE 'analog|speaker|headphone' /proc/asound/pcm; then
        exit 0
      fi
      # Chỉ còn HDMI mà không có analog → reload driver để probe lại codec.
      if ! modprobe -r snd-hda-intel 2>/dev/null; then
        echo "snd-hda-intel đang được dùng — bỏ qua (sẽ tự heal ở lần boot sạch)"
        exit 0
      fi
      modprobe snd-hda-intel
    '';
  };
}
