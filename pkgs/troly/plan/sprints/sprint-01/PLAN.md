# SPRINT 01: Core Architecture & Setup
**Thời gian:** 14/09/2026 - 28/09/2026 | **Trạng thái:** 🟡 IN_PROGRESS | **Phiên bản:** `v01.01.00`

## Mục Tiêu Sprint
Thiết lập toàn bộ khung nền tảng cho package `troly`:
- Cấu hình môi trường NixOS và devenv cô lập.
- Khởi tạo kiến trúc Clean Architecture C++20 phân nhỏ nhất có thể thành các thư mục, tập tin phù hợp, chuyên nghiệp nhằm dễ tìm kiếm và đọc nội dung nhỏ nhất để tiết kiệm tối đa AI token.
- Hệ thống Antigravity IDE Rules & Skills tối ưu token.
- Bộ khung CMakeLists.txt và default.nix sẵn sàng biên dịch.
- **Kế thừa & nâng cấp từ `pkgs/assistant`:** Rà soát và chuẩn bị khung ViewModel/QML cho hệ thống Menu, các cửa sổ thiết lập (RAG, LLM, System, Waka, Profile), cơ chế EyeLeo và Mascot Pet.

## Bảng Công Việc (Sprint Backlog)

| Task ID | Component | Phân loại | Người nhận | Trạng thái | Ghi chú |
|---|---|---|---|---|---|
| `TROLY-101` | NixOS & DevEnv | `chore` | @DevOptAgent | 🟢 DONE | Hoàn thành default.nix, shell.nix, devenv.nix |
| `TROLY-102` | Antigravity Harness | `chore` | @PlanAgent | 🟢 DONE | GEMINI.md, .antigravityignore, 7 skills, Scrum Artifacts |
| `TROLY-103` | Clean Arch Skeleton | `feat` | @DevOptAgent | 🟢 DONE | C++20 Domain & Usecase Interfaces phân rã hạt nhỏ nhất (Atomic) |
| `TROLY-104` | Infra & ViewModel Stubs | `feat` | @DevOptAgent | 🟢 DONE | SqliteRAG, LlamaClient, ChatViewModel module hóa |
| `TROLY-105` | Modern QML GUI Skeleton| `feat` | @DevOptAgent, @AnimAgent | 🟢 DONE | QML Mascot (assets/pet SVG & FSM Disney) & Transparent Window |
| `TROLY-106` | Build System Integration| `chore` | @DevOptAgent | 🟢 DONE | Sửa lỗi Qt6, CMakeLists.txt & derivation nix-build thành công 100% |


---

## Liên Kết Hồ Sơ Agile Scrum Sprint 01
- **Chỉ mục tổng quan:** [README.md](file:///etc/nixos/pkgs/troly/plan/README.md)
- **Kế hoạch & Backlog:** [BACKLOG.md](file:///etc/nixos/pkgs/troly/plan/backlog/BACKLOG.md)
- **Đánh giá bàn giao:** [REVIEW.md](file:///etc/nixos/pkgs/troly/plan/sprints/sprint-01/REVIEW.md)
- **Cải tiến quy trình:** [RETRO.md](file:///etc/nixos/pkgs/troly/plan/sprints/sprint-01/RETRO.md)
- **Nhật ký hàng ngày:** [DAILY_SCRUM.md](file:///etc/nixos/pkgs/troly/plan/scrum/DAILY_SCRUM.md)


