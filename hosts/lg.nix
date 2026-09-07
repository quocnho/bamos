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
  my.gpu.enable = true;
  my.gpu.intelBusId = "PCI:0:2:0";
  my.gpu.nvidiaBusId = "PCI:2:0:0";

  my.power.enable = true; # s2idle + TLP + Battery Care 80%

  # Bootloader: bỏ đếm ngược 5s mặc định của systemd-boot (~4.5s/lần boot chỉ để
  # chờ menu — đo bằng systemd-analyze, không liên quan kernel). Muốn hiện menu
  # chọn generation/kernel cũ: giữ phím SPACE ngay khi logo boot xuất hiện.
  boot.loader.timeout = 0;

  # Kernel ZEN (7.1) — ưu tiên phản hồi nhanh/mượt khi đa nhiệm + OBS/stream
  # (so sánh zen vs default vs latest: modules/boot.nix). Đổi về "default"
  # nếu muốn ưu tiên pin/ổn định. Muốn thử bản khác: `bam boot` → chọn ở boot menu.
  my.boot.kernel = "zen";

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
  services.journald.extraConfig = "SystemMaxUse=400M\nSystemMaxFileSize=50M";

  # (Tag generation "BamOS-YY.MM.DD-HH:MM" giờ nằm ở profiles/common.nix — mọi máy)
  system.stateVersion = "25.11";
}

# bamos installer
