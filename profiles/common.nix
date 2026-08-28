# Profile CƠ BẢN — dành cho MỌI máy NixOS dùng bamos.
# Import toàn bộ module dùng chung (modules/default.nix) + bật các tính năng
# "máy nào cũng cần": âm thanh (PipeWire), bluetooth, ảo hóa (podman), nix-ld,
# locale tiếng Việt (fcitx5-unikey), shell zsh, font chữ...
#
# Máy đích cài từ ISO dùng profile này qua:
#   bamos.profiles.common  (xem installer/flake.nix trên máy đích)
{ config, lib, ... }:

{
  imports = [ ../modules/default.nix ];

  # Âm thanh: PipeWire + mic ảo khử tiếng ồn (rnnoise)
  my.audio.enable = true;
}
