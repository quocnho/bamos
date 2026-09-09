# Host "lg" — LG laptop (Intel UHD CometLake + NVIDIA GTX 1650).
#
# = Desktop profile (common + gnome + macos + boot + assets)
# = Phần riêng máy này: GPU (my.gpu + bus IDs), nguồn điện (my.power), user.
#
# Lưu ý: user "quocnho" khai báo TRỰC TIẾP ở đây (không hardcode trong
# modules/) — máy khác cài qua ISO tự tạo user riêng ở bước Users của Calamares.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../profiles/desktop.nix
    ../hardware-configuration.nix
  ];

  networking.hostName = "lg";

  # ==== Hostname ảo cho dev (domain local .test) ====
  # quocnho.test → 127.0.0.1 (dùng cho dev web/local HTTPS cert…)
  networking.hosts."127.0.0.1" = [ "quocnho.test" ];

  # Cho phép process không-root bind cổng thấp (<1024) — tiện cho dev
  # (server test port 80/443, podman rootless…). Lưu ý: giảm an toàn mạng
  # cục bộ một chút — nếu không cần nữa hãy xoá/xét lại giá trị này.
  boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = 0;

  # ==== Người dùng (riêng host này) ====
  # initialPassword chỉ dùng lần đăng nhập đầu — đổi ngay sau khi vào máy:
  #   passwd
  users.users.quocnho = {
    isNormalUser = true;
    description = "quocnho";
    # extraGroups đầy đủ: wifi (networkmanager), bluetooth, input, video/audio,
    # in ấn (lp/scanner), mount ổ đĩa (disk/storage), sudo (wheel), podman...
    extraGroups = [
      "networkmanager"
      "wheel"
      "bluetooth"
      "input"
      "video"
      "audio"
      "render"
      "disk"
      "storage"
      "lp"
      "scanner"
      "power"
      "podman"
    ];
    initialPassword = "j";
    shell = pkgs.zsh;
  };

  # ==== Phần riêng của máy LG ====
  my.dev.enable = true; # công cụ dev: Zed, Antigravity, Python, Node, devenv...
  my.ai.enable = true;  # Local AI (llama-server, Qwen2.5-1.5B) - on-demand
  my.rag.enable = true; # RAG service (chromem-go) - on-demand
  my.gpu.enable = true;
  my.gpu.intelBusId = "PCI:0:2:0";
  my.gpu.nvidiaBusId = "PCI:2:0:0";

  my.power.enable = true; # s2idle + TLP + Battery Care 80%

  # Bootloader: bỏ đếm ngược 5s mặc định của systemd-boot (~4.5s/lần boot chỉ để
  # chờ menu — đo bằng systemd-analyze, không liên quan kernel). Muốn hiện menu
  # chọn generation/kernel cũ: giữ phím SPACE ngay khi logo boot xuất hiện.
  boot.loader.timeout = 0;

  # Kernel LATEST (mainline mới nhất) — theo yêu cầu. Lưu ý: nixpkgs update liên
  # tục sẽ rebuild kernel + driver NVIDIA mỗi tuần; muốn ổn định/pin hơn đổi về
  # "default"/"zen". So sánh đầy đủ ở modules/boot.nix.
  my.boot.kernel = "latest";

  # ==== Studio (edition studio-pro theo GLF-OS) — ghi hình + livestream OBS ====
  # OBS + NVENC (chạy bằng `obs-nvenc`) / VAAPI iGPU / x264 + GIMP, Audacity,
  # fonts sáng tạo, công cụ đa phương tiện. Tùy chọn nặng (DaVinci Resolve,
  # Kdenlive, REAPER) mặc định TẮT — xem modules/studio.nix để bật.
  my.studio.enable = true;

  # ==== Máy DEVELOPER — gọn, nhẹ, không app chạy ngầm thừa ====
  # GNOME Software + Flatpak backend: cài app bằng Nix là đủ → bỏ ~160MB
  # gnome-software + flatpak helpers chạy ngầm + refresh kho Flathub định kỳ.
  # (Máy cài từ ISO vẫn có store — mặc định my.gnome.store = true.)
  my.gnome.store = false;

  # (acpid giữ NGUYÊN: module nvidia.nix của nixpkgs tự bật cho quản lý nguồn
  #  NVIDIA — daemon rất nhỏ, không đáng tắt bằng mkForce.)

  # Journald: giới hạn log ổn định (không phình vô hạn trên SSD 512GB)
  # Cú pháp mới của nixpkgs (extraConfig đã bị loại bỏ → assertion lỗi)
  services.journald.settings.Journal = {
    SystemMaxUse = "400M";
    SystemMaxFileSize = "50M";
  };

  # (Tag generation "BamOS-YY.MM.DD-HH:MM" giờ nằm ở profiles/common.nix — mọi máy)
  system.stateVersion = "25.11";
}

# bamos installer
