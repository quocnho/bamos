{ lib, ... }:

{
  # ═══════════════════════════════════════════════════════
  # Tắt các dịch vụ không cần thiết
  # ═══════════════════════════════════════════════════════
  services.printing.enable = false;
  services.avahi.enable = false;
  services.power-profiles-daemon.enable = false;

  # ═══════════════════════════════════════════════════════
  # Tắt documentation để giảm dung lượng ISO và build time
  # ═══════════════════════════════════════════════════════
  documentation.nixos.enable = false;
  documentation.doc.enable = false;
  documentation.man.enable = false;
  documentation.info.enable = false;
}
