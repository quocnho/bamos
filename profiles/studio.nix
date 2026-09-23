# Profile STUDIO — Sáng tạo nội dung, ghi hình, livestream, âm thanh
# Kế thừa profile desktop + bật bộ studio
{ config, lib, ... }:

{
  imports = [ ./desktop.nix ];

  # Bật OBS Studio + V4L2 virtual camera + NVENC / VAAPI plugin + GIMP, Audacity, creator fonts
  my.studio.enable = true;
}
