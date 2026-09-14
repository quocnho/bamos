---
name: devopt-agent-execute
description: Hướng dẫn viết mã nguồn C++20 Clean Architecture, quản lý RAII, chạy test, đóng gói Nix và kiểm thử cập nhật hệ thống với bam switch cho dự án troly. Kích hoạt khi viết code C++, tạo class, viết unit test, đóng gói package hoặc commit code.
---

# Mục Tiêu
Viết code C++20 an toàn, hiện đại, tuân thủ Clean Architecture theo [docs/ARCHITECTURE.md](file:///etc/nixos/pkgs/troly/docs/ARCHITECTURE.md), đóng gói chuẩn NixOS derivation (package con của flake `/etc/nixos`) và thực hiện quy chuẩn Git Workflow tại [docs/GIT_WORKFLOW.md](file:///etc/nixos/pkgs/troly/docs/GIT_WORKFLOW.md).

> 📦 **Vị Trí Dự Án:** `troly` là một **package con** của cấu hình Flake lớn tại `/etc/nixos/` (tương tự như `/etc/nixos/pkgs/assistant/` và `/etc/nixos/pkgs/bam/`). Khi đóng gói hoặc cập nhật cấu hình hệ thống, @DevOptAgent có trách nhiệm xác thực derivation `nix-build` và kiểm thử toàn hệ thống qua `bam switch`.
> 
> 🔄 **Kế Thừa & Nâng Cấp:** Dự án được tái cấu trúc, phát triển và nâng cấp từ `/etc/nixos/pkgs/assistant/`. Kế thừa trọn vẹn logic từ mã nguồn Go cũ sang C++20: xây dựng ViewModel và Service cho Menu thả nhanh, các cửa sổ thiết lập đa năng (RAG, LLM, System Inspector, WakaTracker, Profile) và hệ thống EyeLeo bảo vệ mắt.

# Quy Chuẩn Clean Architecture & Cấu Trúc Tập Tin Siêu Nhỏ (Atomic Granularity)
- **Phân rã nhỏ nhất có thể:** Xây dựng hệ thống tập tin dự án Clean Architecture và phân nhỏ nhất có thể thành các thư mục, tập tin phù hợp, chuyên nghiệp.
- **Tiết kiệm AI token tối đa:** Đảm bảo dễ tìm kiếm thư mục, tập tin và nội dung nhỏ nhất khi đọc để tiết kiệm AI token trong quá trình dev (tham khảo [docs/ANTIGRAVITY_SETUP.md](file:///etc/nixos/pkgs/troly/docs/ANTIGRAVITY_SETUP.md)).
- **Single Responsibility:** Mỗi file `.hpp`/`.cpp` chỉ chứa một entity, value object, interface hoặc repository cụ thể; không gộp chung nhiều chức năng vào một file fat/god class.

# Quy Chuẩn C++20
- **Smart Pointers**: Ưu tiên `std::unique_ptr` và `std::shared_ptr`. Quản lý tài nguyên C (SQLite, llama) bằng Custom Deleters:
  ```cpp
  using SqliteDbPtr = std::unique_ptr<sqlite3, decltype(&sqlite3_close)>;
  ```
- **Concurrency**: Sử dụng `std::jthread` và `std::stop_token` để ngắt tác vụ mượt mà, tránh block GUI main thread.
- **Interface Segregation**: Tách interface thuần ảo (`= 0`) trong thư mục `src/usecases/`.
- **Zero Raw Pointers for Ownership**: Tuyệt đối không dùng raw pointer nắm giữ quyền sở hữu bộ nhớ.

# Quy Trình Kiểm Thử Đóng Gói Nix, Giao Diện & Hệ Thống (`bam switch`)
Trước khi chốt bàn giao ticket, @DevOptAgent thực hiện chuỗi kiểm thử:
1. **Kiểm tra biên dịch & CTest:** `cmake --build build -j$(nproc) && ctest --test-dir build --output-on-failure`
2. **Chạy Thử Kiểm Tra Giao Diện & Live Preview:**
   - Chạy thử nhị phân: `./build/troly`
   - Live Preview QML nếu có thay đổi UI: `qml6 src/presentation/ui/main.qml`
   - Xác nhận cửa sổ hiển thị không lỗi binding, hiệu ứng mascot cún cưng mượt mà 60fps.
3. **Kiểm tra đóng gói Nix Derivation:** `nix-build -E 'with import <nixpkgs> {}; callPackage ./default.nix {}'` (và chạy thử `./result/bin/troly`).
4. **Kiểm thử cập nhật hệ thống NixOS:** Chạy lệnh của package `/etc/nixos/pkgs/bam`:
   ```bash
   bam dry        # Kiểm tra trước thay đổi
   bam switch     # Áp dụng cấu hình và test switch hệ thống thực tế
   ```

# Quy Chuẩn Git Commit & Versioning (Why - What - Test)
Tuân thủ đầy đủ chuẩn tại [docs/GIT_WORKFLOW.md](file:///etc/nixos/pkgs/troly/docs/GIT_WORKFLOW.md):
```text
<type>(<TICKET-ID>): <short summary> [vAA.BB.CC]

[WHY / BUSINESS CONTEXT]
- Lý do thực hiện thay đổi, bối cảnh nghiệp vụ và nguyên nhân gốc.

[WHAT / SCOPE OF CHANGE]
- Tóm tắt các file và thành phần kỹ thuật được chỉnh sửa.

[TEST / DEFINITION OF DONE]
- [x] Unit tests pass (CTest).
- [x] Compilation pass với GCC 13+ / Clang 16+.
- [x] AddressSanitizer (ASAN) không phát hiện rò rỉ bộ nhớ.
- [x] Chạy thử giao diện (`./build/troly` hoặc `qml6`) đạt hiển thị và preview mượt mà.
- [x] Nix derivation build độc lập (`nix-build ./default.nix`) thành công.
- [x] Hệ thống chuyển đổi thành công với `bam switch`.

Closes: <TICKET-ID>
```

