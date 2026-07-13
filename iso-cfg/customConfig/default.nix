# customConfig/default.nix — 🛡️ User Customizations
# File này KHÔNG bị ghi đè khi cài lại hệ thống!
# Đây là nơi an toàn để thêm cấu hình cá nhân của bạn.
#
# 📝 Cách dùng:
#   Thêm các tùy chỉnh của bạn vào đây, ví dụ:
#
#   - Bật NVIDIA (nếu có GPU rời):
#     bamos.nvidia.enable = true;
#     bamos.nvidia.mode = "nvidia"; # hoặc "sync", "async"
#
#   - Cài thêm packages:
#     environment.systemPackages = with pkgs; [ htop neofetch ];
#
#   - Bật dịch vụ:
#     services.openssh.enable = true;
#     services.flatpak.enable = true;
#
#   - Edition override:
#     bamos.edition = "standard"; # standard | developers | gaming | studio
#
{ ... }:

{
  # ═══════════════════════════════════════════════════════
  # 👤 Thêm cấu hình cá nhân của bạn bên dưới:
  # ═══════════════════════════════════════════════════════
}
