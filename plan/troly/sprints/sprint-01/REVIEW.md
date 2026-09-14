# SPRINT REVIEW: Sprint 01 - Core Architecture & Setup
**Thời gian:** 14/09/2026 - 28/09/2026 | **Người chủ trì:** @PlanAgent | **Trạng thái:** 🟢 COMPLETED | **Phiên bản nghiệm thu:** `v01.01.00`

> 🔄 **Kế thừa & Nâng cấp từ `/etc/nixos/pkgs/assistant/`:** Dự án được tái cấu trúc từ `pkgs/assistant`. Đã nghiên cứu toàn diện hệ thống mã nguồn cũ, xác định các module cần tái hiện trong C++/Qt6: Menu tùy chọn nhanh, các cửa sổ thiết lập, EyeLeo bảo vệ mắt, Bone Context bar.

---

## 1. Kết Quả Chuyển Giao (Delivered Items)

Tổng hợp các hạng mục hoàn thành dựa trên Definition of Done (DoD):

| Task ID | Thành phần | Phân loại | Người thực hiện | Đánh giá DoD | Kết quả nghiệm thu |
|---|---|---|---|---|---|
| `TROLY-101` | NixOS & DevEnv | `chore` | @DevOptAgent | 🟢 PASSED | Môi trường `devenv shell` / `nix-shell` nạp đủ GCC, Qt6, CMake, Ninja |
| `TROLY-102` | Antigravity Harness | `chore` | @PlanAgent | 🟢 PASSED | 9 Skills đồng bộ tại `/etc/nixos/.agents/skills`, GEMINI.md tinh gọn |
| `TROLY-103` | Clean Arch Skeleton | `feat` | @DevOptAgent | 🟢 PASSED | Domain Entities & Usecase Interfaces phân rã vi mô (Atomic Granularity) |
| `TROLY-104` | Infra & ViewModel Stubs | `feat` | @DevOptAgent | 🟢 PASSED | SqliteRAG, LlamaClient, LinuxActionDispatcher, ChatViewModel, SystemMonitorVM |
| `TROLY-105` | Modern QML GUI Skeleton | `feat` | @DevOptAgent, @AnimAgent | 🟢 PASSED | QML Mascot Disney FSM, Bone Context Bar, Smart Chips & 7 Modals kế thừa từ assistant |
| `TROLY-106` | Build & Flake Integration | `chore` | @DevOptAgent | 🟢 PASSED | Derivation `nix-build` thành công 100%, tích hợp flake root `.#troly` |

---

## 2. Bản Demo & Bằng Chứng Kỹ Thuật (Demo & Artifacts)
- **Cấu hình môi trường & Biên dịch:** Chạy lệnh `ninja -C build` và `nix-build -E 'with import <nixpkgs> {}; callPackage ./default.nix {}'` đều thành công 100% không cảnh báo lỗi.
- **Tích hợp Flake cha:** Package `troly` đã được đăng ký chính thức vào `packages.${system}.troly` tại `/etc/nixos/flake.nix`.
- **Rules & Skills:** Kiểm tra 9 kỹ năng chuyên biệt kích hoạt on-demand chuẩn Antigravity IDE.
- **Giao diện & Kế thừa:** Giao diện Fluent Glassmorphism 60fps, Mascot FSM chuyển động mượt mà, đầy đủ các modal chức năng (EyeLeo, RAG, LLM, System, WakaTracker, Profile, About).

---

## 3. Chuyển Giao Sang Sprint 02 (`v01.02.00`)
Sprint 01 đã hoàn thành xuất sắc toàn bộ mục tiêu nền tảng. Chuyển giao toàn bộ các hạng mục F5 và EyeLeo sang Sprint 02 để tập trung hoàn thiện trải nghiệm Desktop Mascot tương tác trực quan người dùng.

---

## 4. Ý Kiến Đóng Góp Từ Stakeholder / User
- Người dùng đã nghiệm thu và đồng thuận 100% với bức tranh sản phẩm hoàn chỉnh và Master Roadmap phân kỳ theo Phương án B.
