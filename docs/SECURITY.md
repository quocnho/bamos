# Security Policy

## Phiên bản được hỗ trợ | Supported Versions

| Version | Supported          |
|---------|--------------------|
| latest  | :white_check_mark: |
| stable  | :white_check_mark: |
| gts     | :white_check_mark: |

## Báo cáo lỗ hổng | Reporting a Vulnerability

Nếu bạn phát hiện lỗ hổng bảo mật trong BamOS, vui lòng báo cáo qua:

If you discover a security vulnerability in BamOS, please report it via:

- **Email**: [Create a security advisory](https://github.com/quocnho/bamos/security/advisories/new)
- **GitHub**: Use the "Report a vulnerability" button in the Security tab

### Quy trình | Process

1. **KHÔNG** tạo issue công khai cho lỗ hổng bảo mật
2. Gửi báo cáo qua GitHub Security Advisory
3. Chúng tôi sẽ phản hồi trong vòng 48 giờ
4. Sau khi xác nhận, chúng tôi sẽ:
   - Đánh giá mức độ nghiêm trọng
   - Phát triển bản vá
   - Phát hành bản cập nhật bảo mật
   - Công bố sau khi bản vá được phát hành

### Bảo mật hình ảnh | Image Security

- Tất cả images được ký bằng **cosign/sigstore**
- Images được lưu trữ trên **ghcr.io** với kiểm soát truy cập
- Cập nhật tự động hàng ngày với các bản vá bảo mật mới nhất từ Fedora upstream

### Khuyến nghị cho người dùng | User Recommendations

- Luôn xác minh chữ ký image trước khi cài đặt
- Sử dụng Secure Boot khi có thể
- Cập nhật hệ thống thường xuyên
- Không cài đặt phần mềm từ nguồn không tin cậy
