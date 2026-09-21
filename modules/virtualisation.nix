# Ảo hóa (podman) & zram.
{ config, lib, pkgs, ... }:

{
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  # Cài đặt podman-compose cấp hệ thống để chạy docker-compose / podman-compose
  environment.systemPackages = [ pkgs.podman-compose ];

  # ==== Tối ưu RAM & Swap nén (zram) ====
  # zstd nén nhanh và hiệu quả, giảm thiểu ghi đĩa SSD, giữ hệ thống phản hồi mượt mà
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50; # 50% RAM (~8GB trên máy 16GB)
    priority = 100;
  };

  # ==== Tối ưu nhân Linux cho RAM, Cache & I/O SSD ====
  boot.kernel.sysctl = {
    # Ưu tiên hoán đổi trang nhớ vào zRAM thay vì thrashing page cache
    "vm.swappiness" = 180;
    # Giữ inode và dentry cache trong RAM lâu hơn để tăng tốc thao tác file
    "vm.vfs_cache_pressure" = 50;
    # Làm mượt ghi đĩa nền (tránh nghẽn I/O đột ngột trên SSD 512GB)
    "vm.dirty_background_bytes" = 134217728; # 128 MB
    "vm.dirty_bytes" = 268435456;            # 256 MB
  };
}
