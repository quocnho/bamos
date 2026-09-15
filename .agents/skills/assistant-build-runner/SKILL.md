---
name: assistant-build-runner
description: Hướng dẫn quản lý môi trường dev shell Go 1.22+, cgo/WebKitGTK3, chạy go test/vet, chạy thử ứng dụng assistant và đóng gói nix package (pkgs/assistant/) kết hợp kiểm thử bam switch. Kích hoạt khi build, chạy thử, test hoặc đóng gói dự án assistant.
---

# Mục Tiêu
Cung cấp quy trình biên dịch cục bộ, kiểm tra mã nguồn Go, chạy thử ứng dụng Desktop WebKit, đóng gói derivation Nix và kiểm thử cập nhật hệ thống NixOS qua `bam switch` cho dự án **`assistant`** (`/etc/nixos/pkgs/assistant/`).

> 📦 **Bối Cảnh Package Con:** `assistant` là một package độc lập nằm tại `/etc/nixos/pkgs/assistant/` trong cấu hình Flake hệ thống BamOS.
> 📍 **Tính Khả Chuyển (Standalone Portability):** Toàn bộ file cấu hình, mã nguồn Go, tài nguyên HTML frontend và scripts phải sử dụng đường dẫn tương đối, không hardcode đường dẫn hệ thống.

---

# Các Lệnh Thao Tác & Kiểm Thử Chuẩn

### 1. Kích Hoạt Môi Trường Dev Shell (Go + GTK3 + WebKitGTK)
Tại thư mục package:
```bash
cd /etc/nixos/pkgs/assistant
direnv allow
# hoặc vào qua nix-shell nếu cần
nix-shell shell.nix
```

### 2. Kiểm Tra Định Dạng & Mã Nguồn Go
```bash
# Định dạng toàn bộ mã Go
go fmt ./...

# Kiểm tra cảnh báo tĩnh
go vet ./...
```

### 3. Chạy Bộ Kiểm Thử Đơn Vị (Unit Test Suite)
```bash
go test -v ./...
```

### 4. Biên Dịch & Chạy Thử Ứng Dụng Cục Bộ
- **Biên dịch binary:**
  ```bash
  go build -o bamos-assistant main.go gui_linux.go ai.go rag.go settings.go wakatracker.go user_profile.go cli_engine.go fs_tools.go system_inspector.go system_info.go
  ```
- **Chạy thử ứng dụng với backend an toàn:**
  ```bash
  # Ưu tiên XWayland để giữ vị trí và tính năng ghim trên cùng
  BAMAI_GDK_BACKEND=x11 ./bamos-assistant
  ```
- *Yêu cầu kiểm tra trực quan:*
  - Cửa sổ hiển thị trong suốt (alpha channel trong suốt, không bị khối đen chữ nhật).
  - Webview hiển thị đầy đủ avatar mascot và thanh nhập liệu.
  - Phản hồi click chuột và menu chuột phải / context menu không bị giật lag.

### 5. Đóng Gói Kiểm Tra Nix Derivation
Kiểm tra tính đúng đắn của file `default.nix`:
```bash
cd /etc/nixos
nix-build -E 'with import <nixpkgs> {}; callPackage ./pkgs/assistant/default.nix {}'
```
Kết quả nhị phân sẽ được sinh tại `./result/bin/bamos-assistant`.

### 6. Kiểm Thử Cập Nhật Hệ Thống NixOS Với `bam`
Khi thay đổi mã nguồn hoặc cập nhật cấu hình package trong hệ thống NixOS:
```bash
# Kiểm tra trước (dry run)
bam dry

# Áp dụng cấu hình và test switch hệ thống thực tế
bam switch
```
