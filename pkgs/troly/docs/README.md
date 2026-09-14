# 📚 Mục Lục Tài Liệu Kỹ Thuật Dự Án Troly (Documentation Index)

Thư mục `/docs/` là trung tâm tri thức kỹ thuật chính thức và toàn diện của dự án **`troly` (Native Edge AI Desktop Companion)**. Toàn bộ tài liệu được phân tách theo miền chuyên trách, hỗ trợ cả lập trình viên và các AI Agent (`@PlanAgent`, `@RdAgent`, `@DevOptAgent`, `@AnimAgent`) tra cứu nhanh chóng và tối ưu token.

---

## 🗂️ Danh Mục Tài Liệu Trọng Tâm

| Tài Liệu | Nội Dung Chính | Đối Tượng Đọc |
| :--- | :--- | :--- |
| 🏗️ [ARCHITECTURE.md](file:///etc/nixos/pkgs/troly/docs/ARCHITECTURE.md) | **Cẩm nang kiến trúc hệ thống toàn diện:**<br>• Triết lý vận hành Air-gapped & Native C++20/Qt6<br>• Phân rã 7 chức năng lớn (F1 - F7)<br>• Tiêu chuẩn Mascot & Hoạt hình 12 nguyên tắc Disney<br>• Lược đồ cơ sở dữ liệu ERD & DDL (SQLite WAL + `vec0` vector)<br>• Biểu đồ luồng dữ liệu DFD Level 1 & ReAct Loop<br>• Chiến lược mô hình Qwen2.5 & fine-tuning GGUF<br>• Kỹ thuật phân rã hạt nhỏ nhất (Atomic Granularity) | `@RdAgent`<br>`@DevOptAgent`<br>`@AnimAgent` |
| 🌿 [GIT_WORKFLOW.md](file:///etc/nixos/pkgs/troly/docs/GIT_WORKFLOW.md) | **Quy chuẩn Git & Quản trị phiên bản:**<br>• Chiến lược đánh số phiên bản 3 cấp `vAA.BB.CC`<br>• Quy tắc đặt tên nhánh theo Ticket ID (`feat/`, `fix/`,...)<br>• Mẫu commit message chuẩn phân tầng (Why - What - Test)<br>• Định nghĩa tiêu chí hoàn thành (Definition of Done - DoD) | `@DevOptAgent`<br>`@PlanAgent` |
| ⚙️ [ANTIGRAVITY_SETUP.md](file:///etc/nixos/pkgs/troly/docs/ANTIGRAVITY_SETUP.md) | **Quy chuẩn Agent Harness & Tối ưu Token:**<br>• Phân biệt Rules (`GEMINI.md`) vs Skills (`SKILL.md`)<br>• Cơ chế nạp ngữ cảnh động (Dynamic Context Injection)<br>• Cấu hình chặn rác ngữ cảnh với `.antigravityignore`<br>• Kỹ thuật Skeleton/Interface Stubs và Atomic Context Window | `@PlanAgent`<br>Solo Coder |

---

## 🔗 Liên Kết Hệ Thống Quản Trị Agile Scrum (`/plan/`)
- 🗺️ **Bản đồ kế hoạch dự án:** [plan/README.md](file:///etc/nixos/pkgs/troly/plan/README.md)
- 📌 **Danh mục yêu cầu tính năng (Backlog):** [plan/backlog/BACKLOG.md](file:///etc/nixos/pkgs/troly/plan/backlog/BACKLOG.md)
- 🏃 **Kế hoạch Sprint 01 hiện tại:** [plan/sprints/sprint-01/PLAN.md](file:///etc/nixos/pkgs/troly/plan/sprints/sprint-01/PLAN.md)
- 📝 **Nhật ký Daily Standup liên Agent:** [plan/scrum/DAILY_SCRUM.md](file:///etc/nixos/pkgs/troly/plan/scrum/DAILY_SCRUM.md)
