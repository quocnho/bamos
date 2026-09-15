# 📚 Mục Lục Tài Liệu Kỹ Thuật Dự Án Assistant (Documentation Index)

Thư mục `/docs/assistant/` là trung tâm tri thức kỹ thuật của dự án **`assistant` (Desktop AI Copilot & System Inspector)** tại `/etc/nixos/pkgs/assistant/`. 

Toàn bộ tài liệu được thiết kế theo chuẩn Markdown UI/UX, phục vụ cả lập trình viên và các AI Agent (`@AssistantPlanAgent`, `@AssistantDevAgent`) tra cứu nhanh và tối ưu ngữ cảnh token.

---

## 🗂️ Danh Mục Tài Liệu Trọng Tâm

| Tài Liệu | Nội Dung Chính | Đối Tượng Đọc |
| :--- | :--- | :--- |
| 🏗️ [ARCHITECTURE.md](file:///etc/nixos/docs/assistant/ARCHITECTURE.md) | **Cẩm nang kiến trúc hệ thống toàn diện:**<br>• Kiến trúc Hybrid Go 1.22+ & WebKitGTK Webview<br>• Phân rã các module cốt lõi (`ai.go`, `gui_linux.go`, `rag.go`, `inspector`)<br>• Cơ chế gọi Local LLM (OpenAI-compatible / llama-server port 9090)<br>• Hệ thống RAG đa tầng: SQLite FTS5 + `sqlite-vec` / `chromem-go`<br>• Giao thức truyền thông hai chiều giữa Webview và Go Backend<br>• Quản trị điện năng GPU NVIDIA (RTD3 0W) & System Inspector | `@AssistantDevAgent`<br>System Engineer |
| 🌿 [GIT_WORKFLOW.md](file:///etc/nixos/docs/assistant/GIT_WORKFLOW.md) | **Quy chuẩn Git & Quản trị phiên bản:**<br>• Chiến lược phiên bản 3 cấp `vAA.BB.CC` (bắt đầu từ `v0.3.0`)<br>• Quy tắc định danh Ticket ID `AST-xxx`<br>• Mẫu commit message phân tầng bắt buộc (Why - What - Test)<br>• Tiêu chuẩn nghiệm thu (Definition of Done - DoD) cho Go codebase | `@AssistantDevAgent`<br>`@AssistantPlanAgent` |

---

## 🔗 Liên Kết Kế Hoạch Agile Scrum (`/plan/assistant/`)
- 🗺️ **Bản đồ kế hoạch dự án Assistant:** [plan/assistant/README.md](file:///etc/nixos/plan/assistant/README.md)
- 📌 **Danh mục yêu cầu tính năng (Backlog):** [plan/assistant/backlog/BACKLOG.md](file:///etc/nixos/plan/assistant/backlog/BACKLOG.md)
- 🏃 **Kế hoạch Sprint 01 hiện tại:** [plan/assistant/sprints/sprint-01/PLAN.md](file:///etc/nixos/plan/assistant/sprints/sprint-01/PLAN.md)
- 📝 **Nhật ký Daily Standup liên Agent:** [plan/assistant/scrum/DAILY_SCRUM.md](file:///etc/nixos/plan/assistant/scrum/DAILY_SCRUM.md)
- 🌐 **Trung tâm tài liệu toàn hệ thống:** [docs/README.md](file:///etc/nixos/docs/README.md)
