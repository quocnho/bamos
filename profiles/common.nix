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

  # ==== Tag generation: tự gắn "BamOS-YY.MM.DD-HH:MM" khi switch/boot (MỌI máy) ====
  # `bam switch` / `bam boot` (và auto-update) set env BAMOS_TAG + chạy nixos-rebuild
  # --impure. Nếu chạy `nixos-rebuild` thủ công (pure) → tryEval thất bại → không có
  # tag, không lỗi. LƯU Ý: nixpkgs chỉ cho ký tự [a-zA-Z0-9:_.-] trong tag nên
  # mẫu gốc "BamOS (YY/mm/dd-hh:mm)" viết lại: "/" → ".", "( )" → "-".
  system.nixos.tags =
    let
      tag = (builtins.tryEval (builtins.getEnv "BAMOS_TAG")).value or "";
    in
    lib.optional (tag != "") tag;
}
