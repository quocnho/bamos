# SPRINT 06: System Inspector, WakaTracker & Adaptive Persona
**Thời gian:** 11/11/2026 - 25/11/2026 | **Trạng thái:** 🟢 COMPLETED | **Phiên bản:** `v01.06.00`

> 🎯 **Mục Tiêu Trọng Tâm Sprint 06:**
> Mở rộng và hoàn thiện bộ ba tiện ích hệ thống (F8 System Extensions), nâng tầm trải nghiệm trợ lý đồng hành chuyên nghiệp và cá nhân hóa:
> 1. Xây dựng **System Inspector Service** đọc và phân tích lỗi `journalctl -p err..emerg`, `systemctl --failed`, dung lượng ổ cứng `/nix/store` và RAM theo thời gian thực.
> 2. Nâng cấp [SystemInspectorModal.qml](file:///etc/nixos/pkgs/troly/src/presentation/ui/SystemInspectorModal.qml) kết nối với ViewModel, quét lỗi hệ thống và hỗ trợ khắc phục nhanh.
> 3. Xây dựng **WakaTracker Service** đo lường nhịp độ lập trình (Local Git Activity & Commit cadence), thống kê thời gian tập trung và tỷ lệ ngôn ngữ code (C++, Nix, QML).
> 4. Nâng cấp [WakaTrackerModal.qml](file:///etc/nixos/pkgs/troly/src/presentation/ui/WakaTrackerModal.qml) hiển thị trực quan biểu đồ nhịp sinh hoạt.
> 5. Xây dựng **UserProfile & Adaptive Persona** lưu trữ xưng hô cá nhân hóa, cấp độ lập trình và tự động đồng bộ vào prompt của [ChatViewModel.cpp](file:///etc/nixos/pkgs/troly/src/presentation/ChatViewModel.cpp).
> 6. Kiểm thử tự động qua CTest (`tests/test_system_inspector.cpp`) và kiểm tra đóng gói Nix derivation.

---

## 📋 Bảng Công Việc (Sprint Backlog)

| Task ID | Component | Phân loại | Người nhận | Ước lượng | Trạng thái | Ghi chú kỹ thuật |
|---|---|---|---|---|---|---|
| `TROLY-601` | System Inspector Service | `feat` | @DevOptAgent | 5 SP | 🟢 DONE | Đọc `systemctl --failed`, `journalctl` lỗi, dung lượng `/nix/store` và RAM |
| `TROLY-602` | System Inspector UI & ViewModel | `feat` | @DevOptAgent | 3 SP | 🟢 DONE | Kết nối `SystemInspectorModal.qml` với `SystemInspectorViewModel` |
| `TROLY-603` | WakaTracker Local Analytics | `feat` | @DevOptAgent | 5 SP | 🟢 DONE | Phân tích commit cadence và file modifications theo ngôn ngữ |
| `TROLY-604` | WakaTracker UI & ViewModel | `feat` | @DevOptAgent | 3 SP | 🟢 DONE | Kết nối `WakaTrackerModal.qml` với `WakaTrackerViewModel` |
| `TROLY-605` | Adaptive Persona & User Profile | `feat` | @RdAgent, @DevOptAgent | 5 SP | 🟢 DONE | Lưu trữ xưng hô, trình độ lập trình và inject vào prompt ngữ cảnh |
| `TROLY-606` | CTest Unit Tests for Extensions | `test` | @DevOptAgent | 3 SP | 🟢 DONE | `tests/test_system_inspector.cpp` kiểm thử chẩn đoán, tracker và persona |
| `TROLY-607` | Flake & NixOS Verification | `chore` | @DevOptAgent | 2 SP | 🟢 DONE | Đóng gói derivation và kiểm tra dry-run flake toplevel |

---

## 👥 Ma Trận Phân Vai (RACI Sprint 06)

- **@PlanAgent:** Theo dõi bảng công việc, điều phối Daily Scrum, nghiệm thu Review & Retro.
- **@RdAgent:** Thiết kế thuật toán phân tích nhịp độ năng suất và prompt persona thích ứng (Adaptive Persona).
- **@DevOptAgent:** Lập trình C++20 Clean Architecture, quản lý đọc log hệ thống an toàn, viết CTest và đóng gói Nix.
- **@AnimAgent:** Thiết kế hoạt ảnh cún cưng động viên khi người dùng đạt mốc tập trung (Pomodoro streak / Waka milestone).

---

## 🔗 Liên Kết Hồ Sơ Agile Scrum
- **Chỉ mục kế hoạch tổng quan:** [plan/troly/README.md](file:///etc/nixos/plan/troly/README.md)
- **Master Product Backlog:** [plan/troly/backlog/BACKLOG.md](file:///etc/nixos/plan/troly/backlog/BACKLOG.md)
- **Sprint 05 Đã Nghiệm Thu:** [plan/troly/sprints/sprint-05/REVIEW.md](file:///etc/nixos/plan/troly/sprints/sprint-05/REVIEW.md)
- **Nhật ký Daily Standup:** [plan/troly/scrum/DAILY_SCRUM.md](file:///etc/nixos/plan/troly/scrum/DAILY_SCRUM.md)
