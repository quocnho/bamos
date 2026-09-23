# ====================================================================
# Tệp cấu hình sinh bởi Bam Customizer (bam-customizer).
# File này khởi tạo sẵn cho máy cài từ ISO để nạp vào hệ thống.
# ====================================================================
{ lib, ... }:
{
  bam.profile = lib.mkDefault "standard";
}
