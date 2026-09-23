# ============================================================================
#  CẤU HÌNH RIÊNG CỦA MÁY BẠN — Bamos
# ============================================================================
#  Đây là nơi bạn thêm/bớt mọi thứ cho hệ điều hành của mình mà KHÔNG cần
#  đụng tới repo (mọi commit mới của bamos vẫn tự cập nhật về máy).
#
#  Cách dùng — MỞ file rồi BỎ COMMENT (#) để bật, THÊM # để tắt:
#    apps.nix       → ứng dụng cài thêm (trình duyệt, văn phòng, media...)
#    features.nix   → tính năng hệ điều hành (in ấn, ssh, firewall, tên máy...)
#    home.nix       → cấu hình NGƯỜI DÙNG qua home-manager (gói riêng, git config...)
#                    (file này được flake.nix import riêng — KHÔNG đặt ở đây)
#
#  Muốn thêm file riêng (vd hardware.nix): tạo file rồi import vào bên dưới.
#
#  Sau khi sửa, cập nhật máy:
#    bam switch                     (áp dụng thay đổi, không cần mạng)
#    sudo nixos-rebuild switch --flake /etc/nixos#bamos
#
#  Muốn tải bản cập nhật mới nhất từ GitHub (config + ứng dụng mới):
#    bam update
# ============================================================================
{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./apps.nix # ứng dụng
    ./features.nix # tính năng hệ điều hành
    ./customized.nix # cấu hình đồng bộ từ Bam Customizer
    # ./hardware.nix # (tùy chọn) thông tin phần cứng riêng
  ];
}
