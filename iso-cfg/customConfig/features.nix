# ============================================================================
#  TÍNH NĂNG HỆ ĐIỀU HÀNH — BỎ COMMENT (#) đầu dòng để BẬT, THÊM # để TẮT
# ============================================================================
#  Sau khi sửa:  sudo nixos-rebuild switch --flake /etc/nixos#bamos
#
#  Những dòng KHÔNG có # là MẶC ĐỊNH bamos bật (muốn tắt thì thêm #).
# ============================================================================
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # ---------------- Mạng ----------------
  networking.networkmanager.enable = true; # wifi + ethernet (bamos bật sẵn)

  # ---------------- Bảo mật ----------------
  networking.firewall.enable = true; # firewall cơ bản

  # ---------------- Dịch vụ ----------------
  services.printing.enable = true; # in ấn (CUPS)
  # services.openssh.enable = true;          # SSH server (cho phép đăng nhập từ xa)
  # services.blueman.enable = true;          # GUI quản lý Bluetooth (GNOME đã có sẵn)

  # ---------------- Năng lượng ----------------
  # Nếu máy là LAPTOP mà khi cài chọn nhầm "Desktop", bật dòng dưới:
  # my.power.enable = true;                  # TLP + suspend sâu (s2idle) + thermald

  # ---------------- Thông tin hệ thống ----------------
  # networking.hostName = "bamos";           # tên máy (mặc định do Calamares đặt)
  # time.timeZone = "Asia/Ho_Chi_Minh";      # múi giờ (mặc định bamos: Việt Nam)
}
