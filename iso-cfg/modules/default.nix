# modules/default.nix — BamOS User Modules
# Aggregator cho các module người dùng.
#
# 📝 Cách dùng:
#   1. Thêm file .nix mới trong thư mục modules/
#   2. Import nó ở dưới đây
#   3. Chạy: sudo nixos-rebuild switch --flake /etc/nixos#bamos
#
# 📌 Lưu ý:
#   - modules/ KHÔNG bị ghi đè khi cài lại hệ thống
#   - customConfig/default.nix là nơi lý tưởng cho config nhỏ
#   - modules/ phù hợp cho các cấu hình phức tạp, nhiều file
#
# Ví dụ:
#   imports = [
#     ./steam.nix        # programs.steam.enable = true
#     ./docker.nix       # virtualisation.docker.enable = true
#     ./dotfiles.nix     # home-manager config
#   ];
#
{ ... }:

{
  imports = [
    # Thêm module của bạn ở đây:
    # ./example.nix
  ];
}
