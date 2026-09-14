---
name: build-runner
description: Hướng dẫn quản lý môi trường NixOS devenv, cấu hình CMake, biên dịch Ninja, đóng gói nix package (package con trong flake /etc/nixos) và kiểm thử cập nhật hệ thống với lệnh bam switch. Kích hoạt khi build dự án, đóng gói package hoặc test bam switch.
---

# Mục Tiêu
Cung cấp quy trình biên dịch cục bộ, xem trước QML, kiểm thử mã nguồn, đóng gói Nix derivation và tích hợp kiểm thử cập nhật toàn hệ thống NixOS thông qua lệnh `bam switch` theo kiến trúc tại [docs/ARCHITECTURE.md](file:///etc/nixos/pkgs/troly/docs/ARCHITECTURE.md).

> 📦 **Bối Cảnh Flake Cha & Package Con:** 
> Dự án `troly` là một **package con** nằm trong hệ thống cấu hình NixOS bằng Flake tổng thể tại `/etc/nixos/` (tương tự như `/etc/nixos/pkgs/assistant/` và `/etc/nixos/pkgs/bam/`). Khi flake `/etc/nixos/` chạy `nix build`, hệ thống sẽ đóng gói và xây dựng các packages.
> 
> 🔄 **Kế Thừa & Nâng Cấp:** Thay thế hoàn toàn Go/WebKitGTK từ `/etc/nixos/pkgs/assistant/` sang hệ thống C++20/Qt6 Native, sử dụng CMake và Ninja.

# Lệnh Build & Preview Nền Tảng

1. **Kích hoạt Dev Shell:**
   ```bash
   direnv allow
   # hoặc
   devenv shell
   ```

2. **Xem trước giao diện QML nhanh (Live Preview):**
   ```bash
   qml6 src/presentation/ui/main.qml
   ```

3. **Cấu hình CMake với Ninja:**
   ```bash
   cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Debug
   ```

4. **Biên dịch song song:**
   ```bash
   cmake --build build -j$(nproc)
   ```

5. **Chạy Bộ Kiểm Thử (Test Suite):**
   ```bash
   ctest --test-dir build --output-on-failure
   ```

6. **Chạy Thử Kiểm Tra Giao Diện & Preview (Bắt Buộc Sau Mỗi Lần Build):**
   - **Chạy thực thi nhị phân đã build:**
     ```bash
     ./build/troly
     ```
   - **Xem trước tương tác Live Preview QML (nếu tinh chỉnh layout/animation):**
     ```bash
     qml6 src/presentation/ui/main.qml
     ```
   - *Yêu cầu kiểm tra:* Cửa sổ trong suốt hiển thị đúng vị trí góc phải dưới màn hình, mascot cún cưng có nhịp thở (Squash & Stretch), các trạng thái FSM chuyển đổi trơn tru, không bị crash hay cảnh báo rò rỉ.

7. **Kiểm tra rò rỉ bộ nhớ với AddressSanitizer:**
   ```bash
   QT_QPA_PLATFORM=wayland ASAN_OPTIONS=detect_leaks=1 ./build/troly
   ```

---

# Quy Trình Đóng Gói Nix Package & Kiểm Thử Toàn Diện

### 1. Đóng gói & Kiểm thử Derivation Package Cục Bộ
Kiểm tra tính độc lập và khả năng đóng gói derivation của package `troly`:
```bash
nix-build -E 'with import <nixpkgs> {}; callPackage ./default.nix {}'
```
Kiểm tra nhị phân sinh ra trong thư mục `result`:
```bash
./result/bin/troly --version # hoặc chạy thử
```

### 2. Đóng gói trong Flake Của Dự Án Lớn (`/etc/nixos`)
Khi được định nghĩa vào `packages.${system}.troly` hoặc tích hợp vào hệ thống tại `/etc/nixos/flake.nix`:
```bash
cd /etc/nixos
nix build .#troly # hoặc nix build . để build toplevel hệ thống
```

### 3. Kiểm Thử Cập Nhật Hệ Thống Với Lệnh `bam switch`
Lệnh `bam switch` là công cụ CLI của package `/etc/nixos/pkgs/bam/` giúp rebuild và switch toàn bộ hệ điều hành BamOS dựa trên flake tại `/etc/nixos/`:
```bash
# Kiểm tra cú pháp/build thử trước (dry run hoặc build)
bam dry
# hoặc
bam build

# Thực hiện rebuild switch hệ thống chính thức
bam switch

# Hoặc nâng cấp kèm cập nhật flake lock
bam switch -u
```
> [!NOTE]
> `bam` tự động nhận diện host (máy dev `lg` hoặc máy người dùng `bamos`), tự xử lý quyền root qua `sudo` và tạo boot generation có tag định danh thời gian `BamOS-YY.MM.DD-HH:MM`.

