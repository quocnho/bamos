# 🏃 SPRINT 01: Kiến Trúc & Củng Cố Hạ Tầng Dự Án Assistant

**Thời gian:** 15/09/2026 - 29/09/2026  
**Trạng thái:** 🟡 **IN_PROGRESS**  
**Phiên bản mục tiêu:** `v0.3.1` (Kế thừa từ `v0.3.0`)  
**Scrum Master / Điều phối:** `@AssistantPlanAgent`  
**Kỹ sư chính:** `@AssistantDevAgent`

---

## 🎯 Mục Tiêu Sprint (Sprint Goal)
1. Xây dựng và đồng bộ hóa toàn bộ tài liệu kiến trúc, quy chuẩn Git và hệ thống quản trị Agile Scrum cho `pkgs/assistant/`.
2. Thiết lập bộ công cụ Agent Skills (`assistant-plan-workflow`, `assistant-build-runner`, `assistant-dev-guide`) chuyên trách.
3. Rà soát, củng cố tính ổn định của luồng Go WebKitGTK, giám sát nguồn GPU RTD3 và bộ nhớ RAG SQLite.

---

## 📋 Bảng Phân Công Công Việc (Sprint Backlog)

| Task ID | Thành Phần | Loại Việc | Người Nhận | Trạng Thái | Ghi Chú |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `AST-101` | Docs / Scrum | `docs` | `@AssistantPlanAgent` | 🟢 **DONE** | Tạo `/docs/assistant/` và cấu trúc `/plan/assistant/` |
| `AST-102` | Agent Skills | `chore` | `@AssistantPlanAgent` | 🟢 **DONE** | Tạo bộ 3 skill chuyên biệt trong `.agents/skills/` |
| `AST-103` | GUI / Engine | `fix` | `@AssistantDevAgent` | 🟢 **DONE** | Cơ chế `WEBKIT_DISABLE_DMABUF_RENDERER` & X11 backend |
| `AST-104` | RAG Engine | `refactor` | `@AssistantDevAgent` | 🟡 **IN_PROGRESS** | Rà soát chunking & SQLite FTS5 index |
| `AST-105` | System Inspector | `feat` | `@AssistantDevAgent` | 🟡 **IN_PROGRESS** | Bảo vệ GPU NVIDIA RTD3 0W không bị đánh thức giả |
| `AST-106` | AI Orchestrator | `feat` | `@AssistantDevAgent` | ⚪ **TODO** | Tinh chỉnh timeout khởi động `llama-server` port 9090 |
| `AST-107` | Nautilus Hook | `chore` | `@AssistantDevAgent` | ⚪ **TODO** | Kiểm tra quyền thực thi và đường dẫn `bam-bone-context` |

---

## 🔍 Tiêu Chí Nghiệm Thu Sprint (Sprint DoD)
- [x] Toàn bộ cây tài liệu kỹ thuật và Agile Scrum hoạt động đầy đủ, liên kết không bị gãy.
- [x] Bộ 3 Agent Skills sẵn sàng hỗ trợ dev shell, build, test và plan.
- [ ] Mã nguồn Go trong `pkgs/assistant/` vượt qua `go vet` và kiểm tra đóng gói `nix-build`.
- [ ] Kiểm thử chạy thực tế ứng dụng ổn định trên màn hình desktop Linux.
