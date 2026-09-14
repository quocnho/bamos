# SPRINT 05: Action Dispatcher, Safety Guard & ReAct Loop
**Thời gian:** 28/10/2026 - 11/11/2026 | **Trạng thái:** 🟢 COMPLETED | **Phiên bản:** `v01.05.00`

> 🎯 **Mục Tiêu Trọng Tâm Sprint 05:**
> Hiện thực hóa năng lực tự động hóa tác vụ hệ điều hành Linux/NixOS thông minh (Autonomous Action Execution) với rào chắn an toàn tối đa:
> 1. Xây dựng **SafetyGuard Engine** phân loại rủi ro 4 cấp độ (`Safe`, `Caution`, `Dangerous`, `Blocked`), bảo vệ an toàn tệp tin và hệ điều hành.
> 2. Giao diện **Human-in-the-Loop Confirmation Modal** bắt buộc người dùng phê duyệt trước khi thực thi lệnh nguy hiểm (`Dangerous`/`Caution`).
> 3. Nâng cấp **LinuxActionDispatcher** C++20 `QProcess` stream realtime stdout/stderr, xử lý timeout và hủy tác vụ qua `std::stop_token`.
> 4. Vòng lặp tự sửa lỗi **ReAct Self-Correction Cycle** (Reasoning ➔ Action ➔ Observation ➔ Reflection).
> 5. Bảng ghi nhật ký kiểm toán **SQLite Audit Trail (`action_logs`)**.
> 6. Kiểm thử CTest (`tests/test_action.cpp`) và đóng gói Nix derivation.

---

## 📋 Bảng Công Việc (Sprint Backlog)

| Task ID | Component | Phân loại | Người nhận | Ước lượng | Trạng thái | Ghi chú kỹ thuật |
|---|---|---|---|---|---|---|
| `TROLY-501` | Safety Guard & Risk Analyzer | `feat` | @DevOptAgent | 5 SP | 🟢 DONE | Phân loại 4 cấp độ: `Safe`, `Caution`, `Dangerous`, `Blocked`. Regex & blacklist |
| `TROLY-502` | Human-in-the-Loop UI Modal | `feat` | @DevOptAgent | 5 SP | 🟢 DONE | `SafetyConfirmationModal.qml` cảnh báo đỏ, yêu cầu phê duyệt người dùng |
| `TROLY-503` | Realtime Subprocess Dispatcher | `feat` | @DevOptAgent | 5 SP | 🟢 DONE | Bắt luồng stdout/stderr theo chunk, timeout timeoutMs, hủy luồng an toàn |
| `TROLY-504` | ReAct Self-Correction Cycle | `feat` | @RdAgent, @DevOptAgent | 5 SP | 🟢 DONE | Phân tích exit code lỗi, tự động đề xuất lệnh thay thế khắc phục sự cố |
| `TROLY-505` | SQLite Audit Log (`action_logs`) | `feat` | @DevOptAgent | 3 SP | 🟢 DONE | Ghi nhận timestamp, command, risk level, approved, exitCode vào DB |
| `TROLY-506` | CTest Unit Tests for Action | `test` | @DevOptAgent | 3 SP | 🟢 DONE | `tests/test_action.cpp` kiểm thử 100% (SafetyGuard, Dispatcher, Audit) |
| `TROLY-507` | Flake & NixOS Verification | `chore` | @DevOptAgent | 2 SP | 🟢 DONE | Đóng gói derivation và kiểm tra dry-run flake toplevel thành công 100% |

---

## 👥 Ma Trận Phân Vai (RACI Sprint 05)

- **@PlanAgent:** Theo dõi bảng công việc, điều phối Daily Scrum, nghiệm thu Review & Retro.
- **@RdAgent:** Thiết kế tập luật phân tích rủi ro lệnh nhạy cảm (Risk Analyzer) và prompt template cho ReAct Loop.
- **@DevOptAgent:** Lập trình C++20 Clean Architecture, quản lý `QProcess` RAII, viết CTest và đóng gói Nix.
- **@AnimAgent:** Thiết kế hoạt ảnh cún cưng cảnh giác / cảnh báo đỏ khi phát hiện lệnh nguy hiểm (`alert` state).

---

## 🔗 Liên Kết Hồ Sơ Agile Scrum
- **Chỉ mục kế hoạch tổng quan:** [plan/troly/README.md](file:///etc/nixos/plan/troly/README.md)
- **Master Product Backlog:** [plan/troly/backlog/BACKLOG.md](file:///etc/nixos/plan/troly/backlog/BACKLOG.md)
- **Sprint 04 Đã Nghiệm Thu:** [plan/troly/sprints/sprint-04/REVIEW.md](file:///etc/nixos/plan/troly/sprints/sprint-04/REVIEW.md)
- **Nhật ký Daily Standup:** [plan/troly/scrum/DAILY_SCRUM.md](file:///etc/nixos/plan/troly/scrum/DAILY_SCRUM.md)
