# 🏃 SPRINT 02: Kiến Trúc Wails v3, Screen Docking 4 Góc & Đa Linh Vật Mascot

**Thời gian:** 16/09/2026 - 30/09/2026  
**Trạng thái:** 🟢 **IN_PROGRESS (Release v01.12.02)**  
**Phiên bản mục tiêu:** `v0.3.2` (System Release Tag: `v01.12.02`)  
**Scrum Master / Điều phối:** `@AssistantPlanAgent`  
**Kỹ sư chính:** `@AssistantDevAgent`

---

## 🎯 Mục Tiêu Sprint (Sprint Goal)
1. Cấu trúc lại toàn bộ CSS frontend theo mô hình phân tầng module (`css/base/`, `css/components/`, `css/modals/`).
2. Hiện đại hóa cầu nối backend-frontend theo chuẩn Golang Wails v3 (IPC Shim & Events).
3. Loại bỏ hoàn toàn kéo thả tự do, triển khai neo 4 góc màn hình (4-corner screen docking) chính xác theo workarea.
4. Bổ sung modal thiết lập Appearance (Giao diện) và Động cơ Đa Linh Vật thời gian thực (Puppy, Cat, Rabbit, Wizard).

---

## 📋 Bảng Phân Công Công Việc (Sprint Backlog)

| Task ID | Thành Phần | Loại Việc | Người Nhận | Trạng Thái | Ghi Chú |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `AST-114` | Frontend CSS | `refactor` | `@AssistantDevAgent` | 🟢 **DONE** | Phân rã CSS thành thư mục base, components, modals |
| `AST-115` | Backend GUI | `feat` | `@AssistantDevAgent` | 🟢 **DONE** | Cầu nối Wails v3, docking 4 góc, bỏ cơ chế drag |
| `AST-116` | Frontend Mascot | `feat` | `@AssistantDevAgent` | 🟢 **DONE** | Modal Appearance & Mascot Vector Engine 4 nhân vật |
| `AST-104` | RAG Engine | `feat` | `@AssistantDevAgent` | 🟡 **IN_PROGRESS** | Phân đoạn văn bản & Hybrid search (FTS5 + vector) |
| `AST-105` | Telemetry | `feat` | `@AssistantDevAgent` | 🟡 **IN_PROGRESS** | Giám sát RTD3 GPU an toàn 0W |

---

## 🔍 Tiêu Chí Nghiệm Thu (Sprint DoD)
- [x] CSS frontend được phân tách rõ ràng, không còn 2 file CSS nguyên khối hơn 2.900 dòng.
- [x] Backend Golang tương thích Wails v3 IPC, neo chính xác 4 góc không bị lệch tọa độ.
- [x] Mascot Engine cho phép đổi mượt mà giữa Chó, Mèo, Thỏ và Ông Bụt.
- [x] `nix-build` thành công, không phát sinh lỗi biên dịch CGO.
