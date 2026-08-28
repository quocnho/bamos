# ============================================================================
#  TÍNH NĂNG HỆ ĐIỀU HÀNH — BỎ COMMENT (#) đầu dòng để BẬT, THÊM # để TẮT
# ============================================================================
#  Sau khi sửa:  sudo nixos-rebuild switch --flake /etc/nixos#bamos
#
#  Những dòng KHÔNG có # là MẶC ĐỊNH BamOS bật (muốn tắt thì thêm #).
#  Phù hợp website bamos.info — "Hệ điều hành cho người Việt Nam",
#  triết lý "Cây tre trăm đốt": cài xong là dùng, không cần cài thêm.
# ============================================================================
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # ---------------- Mạng ----------------
  networking.networkmanager.enable = true; # wifi + ethernet (BamOS bật sẵn)

  # ---------------- Bảo mật ----------------
  networking.firewall.enable = true; # firewall cơ bản

  # ---------------- Dịch vụ ----------------
  services.printing.enable = true; # in ấn (CUPS)
  # services.openssh.enable = true; # SSH server (cho phép đăng nhập từ xa)

  # ---------------- Ngôn ngữ & bộ gõ tiếng Việt (mặc định BamOS) ----------------
  time.timeZone = "Asia/Ho_Chi_Minh"; # múi giờ Việt Nam (mặc định)

  # Bộ gõ tiếng Việt: fcitx5 + Unikey — gõ tiếng Việt mọi lúc, không cần cài thêm.
  # (Đã bật sẵn trong profile common — để đây cho rõ / muốn đổi thì sửa.)
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [ qt6Packages.fcitx5-unikey ];
  };

  # ---------------- Ứng dụng cơ bản cho người dùng văn phòng ----------------
  # Theo bamos.info: "Cài xong là dùng". WPS Office / Chrome / Zoom là phần
  # mềm không tự do (unfree) nên cần cho phép:
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    # ---- Văn phòng (tương thích Microsoft Office — bamos.info) ----
    wpsoffice # soạn thảo văn bản, bảng tính, trình chiếu
    # ---- Trình duyệt (đồng bộ bookmark, mật khẩu, tiện ích) ----
    google-chrome
    # ---- Họp hành trực tuyến ----
    zoom-us # họp online
    # Zalo: chưa có package trong nixpkgs — tải AppImage từ https://zalo.me
    #   hoặc cài qua: nixpkgs#distrobox + distrobox create -n zalo ...
    # ---- Sáng tạo (tùy chọn — bỏ comment để cài) ----
    # gimp        # chỉnh sửa ảnh
    # kdenlive    # dựng video
    # obs-studio  # quay màn hình / stream
  ];

  # ---------------- Năng lượng ----------------
  # Nếu máy là LAPTOP mà khi cài chọn nhầm "Desktop", bật dòng dưới:
  # my.power.enable = true; # TLP + suspend sâu (s2idle) + thermald

  # ---------------- Thông tin hệ thống ----------------
  # networking.hostName = "bamos"; # tên máy (mặc định do Calamares đặt)
}
