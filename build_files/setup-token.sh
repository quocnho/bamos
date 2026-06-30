#!/bin/bash
# setup-token.sh
# Configure USB Token and Digital Signature support for Vietnamese users
# Supports: Viettel-CA, BKAV-CA, FPT-CA, VNPT-CA tokens

set -e

echo "Setting up USB Token / Digital Signature support..."

# Enable PC/SC smart card daemon
systemctl enable pcscd || true

# Create PKCS#11 module configuration
mkdir -p /etc/pkcs11/ 2>/dev/null || true

# Create directories for token middleware
mkdir -p /usr/local/lib/token/ 2>/dev/null || true

# Configure Firefox/Chromium for digital signing
# Add PKCS#11 module loading script
cat > /etc/profile.d/bamos-token.sh << 'EOF'
#!/bin/bash
# Load PKCS#11 module for browser digital signing
export PKCS11_MODULE_PATH="/usr/lib64/pkcs11/"
export PKCS11_PROXY_SOCKET="tcp://127.0.0.1:5657"
EOF

chmod +x /etc/profile.d/bamos-token.sh

# Create documentation for token setup
mkdir -p /usr/share/doc/bamos/
cat > /usr/share/doc/bamos/TOKEN-SETUP.md << 'EOF'
# Hướng dẫn thiết lập chữ ký số (USB Token) trên BamOS

## Token được hỗ trợ
- Token VIETTEL-CA
- Token BKAV-CA
- Token FPT-CA
- Token VNPT-CA
- Gemalto/Thales SafeNet

## Cách sử dụng

### 1. Cắm USB Token vào máy tính
### 2. Cài đặt driver cho token của bạn:
   - Truy cập trang web nhà cung cấp CA
   - Tải driver Linux (.rpm hoặc .deb)
   - Cài đặt: sudo rpm-ostree install <package>

### 3. Cấu hình trình duyệt:
   - Firefox: Settings > Privacy & Security > Security Devices > Load
   - Chrome: Settings > Privacy and security > Manage certificates

### 4. Sử dụng chữ ký số:
   - Kê khai thuế: https://thuedientu.gdt.gov.vn
   - Bảo hiểm xã hội: https://baohiemxahoi.gov.vn
   - Hải quan: https://customs.gov.vn

## Lưu ý quan trọng
- Luôn tải driver từ trang web chính thức của nhà cung cấp CA
- Không chia sẻ mã PIN token với người khác
- Rút token khỏi máy tính sau khi sử dụng
EOF

echo "USB Token / Digital Signature setup complete!"
echo "See /usr/share/doc/bamos/TOKEN-SETUP.md for detailed instructions (Vietnamese)."
