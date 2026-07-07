# lib/utils.nix
# Helper functions dùng chung cho toàn bộ dự án
{ lib }:
{
  # Tạo tên ISO chuẩn: bamos-<desktop>-<edition>-<version>.iso
  mkISOName =
    { desktop, edition, version }:
    "bamos-${desktop}-${edition}-${version}.iso";

  # Danh sách tất cả desktop environments được hỗ trợ
  supportedDEs = [ "gnome" "kde" "cosmic" ];

  # Danh sách tất cả editions được hỗ trợ
  supportedEditions = [ "standard" "developers" "gaming" "studio" ];
}
