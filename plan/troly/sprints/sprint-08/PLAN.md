# SPRINT 08: Hybrid Expansion (Autonomous Agent Tools & Desktop Pet Polish)
**Thời gian:** 11/12/2026 - 25/12/2026 | **Trạng thái:** 🟢 COMPLETED | **Phiên bản:** `v01.08.00`

> 🎯 **Mục Tiêu Trọng Tâm Sprint 08:**
> Tiến hóa `troly` từ bộ khung hoàn chỉnh sang giải pháp sản phẩm đột phá kết hợp (Hybrid Approach) giữa:
> 1. **Autonomous Agent Tools & System Interop:**
>    - Mở rộng kho Tools cho ReAct Agent: Liệt kê thư mục/tệp tin (`listDirectory`), tìm kiếm chuỗi nội dung (`searchInFiles`), và kiểm tra cú pháp cấu hình NixOS (`validateNixConfig`).
>    - Thêm API thực thi và phản hồi tool calling trong `IActionDispatcher` và `ActionViewModel`.
> 2. **Desktop Pet Companion Polish & Interactive Audio:**
>    - Tích hợp hiệu ứng âm thanh Native phản hồi tương tác cún cưng (`AudioFeedbackService`: tiếng sủa thân thiện, âm chu kỳ EyeLeo, thông báo lệnh hoàn tất).
>    - Nâng cấp `Mascot3DPOC.qml` với tương tác vuốt ve trỏ chuột (Petting / Scratching physics) và biểu cảm linh hoạt theo trạng thái Agent.
> 3. **Kiểm thử tự động & Đóng gói:**
>    - Bổ sung CTest suite `test_agent_tools.cpp`, đảm bảo 100% test suites passed (7/7 suites).
>    - Kiểm tra đóng gói Nix derivation và cập nhật hệ thống.

---

## 📋 Bảng Công Việc (Sprint Backlog)

| Task ID | Component | Phân loại | Người nhận | Ước lượng | Trạng thái | Ghi chú kỹ thuật |
|---|---|---|---|---|---|---|
| `TROLY-801` | Agent Tools Expansion (FS & Search) | `feat` | @DevOptAgent | 5 SP | 🟢 DONE | Bổ sung `listDirectory`, `searchInFiles`, `validateNixConfig` vào `IActionDispatcher` |
| `TROLY-802` | Action ViewModel Tooling & UI | `feat` | @DevOptAgent | 3 SP | 🟢 DONE | Mở rộng `ActionViewModel` hỗ trợ gọi Tool trực tiếp và hiển thị chi tiết trên QML |
| `TROLY-803` | Audio Feedback & Mascot Sound Service | `feat` | @DevOptAgent, @AnimAgent | 5 SP | 🟢 DONE | Âm thanh gâu gâu thân thiện, thông báo EyeLeo và hoàn thành task không giật GUI |
| `TROLY-804` | 3D Mascot Petting & Disney Dynamics | `feat` | @AnimAgent | 5 SP | 🟢 DONE | Cải tiến `Mascot3DPOC.qml` hỗ trợ vuốt ve trỏ chuột, Squash & Stretch khi được xoa đầu |
| `TROLY-805` | CTest Suite `test_agent_tools` & Packaging | `test` | @DevOptAgent | 3 SP | 🟢 DONE | Bộ test kiểm thử toàn diện Tools mới, đạt 7/7 CTest passed và `nix-build default.nix` |

---

## 👥 Ma Trận Phân Vai (RACI Sprint 08)

- **@PlanAgent:** Quản trị Sprint Backlog, nhật ký Daily Scrum và hồ sơ nghiệm thu Sprint 08.
- **@RdAgent:** Nghiên cứu cấu trúc JSON Tool Calling và giải pháp âm thanh phản hồi hiệu năng cao.
- **@DevOptAgent:** Hiện thực hóa C++20 Clean Architecture, Action Dispatcher mở rộng, Sound Service và CTest.
- **@AnimAgent:** Thiết kế chuyển động vuốt ve 3D và tinh chỉnh hoạt ảnh biểu cảm cho Mascot.

---

## 🔗 Liên Kết Hồ Sơ Agile Scrum
- **Chỉ mục kế hoạch tổng quan:** [plan/troly/README.md](file:///etc/nixos/plan/troly/README.md)
- **Master Product Backlog:** [plan/troly/backlog/BACKLOG.md](file:///etc/nixos/plan/troly/backlog/BACKLOG.md)
- **Nhật ký Daily Standup:** [plan/troly/scrum/DAILY_SCRUM.md](file:///etc/nixos/plan/troly/scrum/DAILY_SCRUM.md)
