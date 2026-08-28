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

  # ---------------- Văn phòng: LibreOffice + Google (mặc định BamOS) ----------------
  #
  # ▶ LỰA CHỌN OFFICE (phân tích lỗi font/symbol của WPS):
  #   1. LibreOffice (mặc định) — FOSS, ổn định, font tiếng Việt chuẩn (dùng fontconfig
  #      hệ thống), KHÔNG lỗi symbol. Tương thích tốt tài liệu MS Office.
  #   2. Google Docs/Sheets/Slides (web apps, cài sẵn) — nhẹ, miễn phí, đồng bộ đám mây,
  #      không lỗi font (web render). Cần internet + tài khoản Google.
  #   3. WPS Office (TÙY CHỌN — comment bên dưới) — tương thích MS Office tốt nhất NHƯNG
  #      hay lỗi font tiếng Việt & symbol (ô vuông ☺☻); cần font MS + Symbola (đã cài).
  #
  # WPS Office / Chrome / Zoom là phần mềm không tự do (unfree) nên cần cho phép:
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    # ---- Văn phòng OFFLINE (mặc định: LibreOffice — ổn định font tiếng Việt) ----
    libreoffice # soạn thảo văn bản, bảng tính, trình chiếu (tương thích MS Office)

    # ---- WPS Office (TÙY CHỌN) — comment 2 dòng dưới để cài ----
    # LƯU Ý: nếu thấy ô vuông ☺☻/lỗi font, kiểm tra font MS (corefonts) + Symbola
    # (cả 2 đã được BamOS cài sẵn trong modules/assets.nix).
    # wpsoffice

    # ---- Trình duyệt (đồng bộ bookmark, mật khẩu, tiện ích) ----
    google-chrome
    # ---- Họp hành trực tuyến ----
    zoom-us # họp online
    # Zalo: chưa có package trong nixpkgs — tải AppImage từ https://zalo.me
    #   hoặc cài qua: nixpkgs#distrobox + distrobox create -n zalo ...

    # ---- Google Docs / Sheets / Slides — web apps cài sẵn (kiểu Bazzite) ----
    # Mở như app riêng (cửa sổ không thanh tab), dùng chung tài khoản Google của Chrome.
    # Cần internet; đăng nhập Google 1 lần ở Chrome là dùng được cả 3.
    (pkgs.makeDesktopItem {
      name = "google-docs";
      desktopName = "Google Docs";
      comment = "Soạn thảo văn bản trực tuyến (Google)";
      exec = "google-chrome-stable --app=https://docs.google.com/document/u/0/";
      icon = "x-office-document";
      categories = [
        "Office"
        "Network"
      ];
      startupNotify = false;
    })
    (pkgs.makeDesktopItem {
      name = "google-sheets";
      desktopName = "Google Sheets";
      comment = "Bảng tính trực tuyến (Google)";
      exec = "google-chrome-stable --app=https://docs.google.com/spreadsheets/u/0/";
      icon = "x-office-spreadsheet";
      categories = [
        "Office"
        "Network"
      ];
      startupNotify = false;
    })
    (pkgs.makeDesktopItem {
      name = "google-slides";
      desktopName = "Google Slides";
      comment = "Trình chiếu trực tuyến (Google)";
      exec = "google-chrome-stable --app=https://docs.google.com/presentation/u/0/";
      icon = "x-office-presentation";
      categories = [
        "Office"
        "Network"
      ];
      startupNotify = false;
    })
    # Google Drive (thêm nếu cần — bỏ comment):
    # (pkgs.makeDesktopItem {
    #   name = "google-drive";
    #   desktopName = "Google Drive";
    #   comment = "Lưu trữ đám mây (Google)";
    #   exec = "google-chrome-stable --app=https://drive.google.com";
    #   icon = "folder-remote";
    #   categories = [ "Network" ];
    #   startupNotify = false;
    # })
  ];

  # ---------------- Năng lượng ----------------
  # Nếu máy là LAPTOP mà khi cài chọn nhầm "Desktop", bật dòng dưới:
  # my.power.enable = true; # TLP + suspend sâu (s2idle) + thermald

  # ---------------- Thông tin hệ thống ----------------
  # networking.hostName = "bamos"; # tên máy (mặc định do Calamares đặt)
}
