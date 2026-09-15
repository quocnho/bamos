# 🏃 SPRINT 01: Kiến Trúc, Module Hóa & Đột Phá Web Widget Studio

**Thời gian:** 15/09/2026 - 29/09/2026  
**Trạng thái:** 🟢 **COMPLETED (v0.3.1)**  
**Phiên bản mục tiêu:** `v0.3.1` (System Release Tag: `v01.11.00`)  
**Scrum Master / Điều phối:** `@AssistantPlanAgent`  
**Kỹ sư chính:** `@AssistantDevAgent`

---

## 🎯 Mục Tiêu Sprint (Sprint Goal)
1. Khắc phục triệt để lỗi giới hạn kích thước cửa sổ settings và neo tọa độ góc dưới bên phải chuẩn xác cho mascot pet.
2. Tối ưu hóa độ ổn định của AI inference: loại bỏ lỗi zombie defunct process của `llama-server`, bổ sung cơ chế Auto-Recovery khi chat stream.
3. Phân rã file nguyên khối `index.html` (hơn 2090 dòng) thành hệ thống template module hóa sạch sẽ `templates/`.
4. Phát triển Studio Nhúng Web Widget hoàn chỉnh: tương đối hóa `baseUrl` trong `embed.js`, xây dựng bộ quét card mạng IP/Hostname máy tính tự động.

---

## 📋 Bảng Phân Công Công Việc (Sprint Backlog)

| Task ID | Thành Phần | Loại Việc | Người Nhận | Trạng Thái | Ghi Chú |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `AST-101` | Docs / Scrum | `docs` | `@AssistantPlanAgent` | 🟢 **DONE** | Tạo `/docs/assistant/` và cấu trúc `/plan/assistant/` |
| `AST-102` | Agent Skills | `chore` | `@AssistantPlanAgent` | 🟢 **DONE** | Tạo bộ 3 skill chuyên biệt trong `.agents/skills/` |
| `AST-103` | GUI / Engine | `fix` | `@AssistantDevAgent` | 🟢 **DONE** | Cơ chế `WEBKIT_DISABLE_DMABUF_RENDERER` & X11 backend |
| `AST-110` | GUI Window | `fix` | `@AssistantDevAgent` | 🟢 **DONE** | Bỏ `MAX_FIT_HEIGHT`, neo cố định góc dưới-phải màn hình |
| `AST-111` | AI Engine | `fix` | `@AssistantDevAgent` | 🟢 **DONE** | Thu hồi child process, Auto-Recovery khi llama-server offline |
| `AST-112` | Frontend UI | `refactor` | `@AssistantDevAgent` | 🟢 **DONE** | Tách `index.html` thành 14 templates độc lập trong `templates/` |
| `AST-113` | Web Widget | `feat` | `@AssistantDevAgent` | 🟢 **DONE** | Web Widget Studio, relative baseUrl & IP/Hostname network discovery |

---

## 🔍 Tiêu Chí Nghiệm Thu Sprint (Sprint DoD)
- [x] Toàn bộ cây tài liệu kỹ thuật và Agile Scrum hoạt động đầy đủ, liên kết không bị gãy.
- [x] Giao diện không bị giới hạn kích thước; neo góc dưới bên phải giữ vị trí mascot cố định.
- [x] Không còn hiện tượng treo vĩnh viễn "Em đang tra cứu và xử lý..."; tự phục hồi khi offline.
- [x] File `index.html` thu gọn từ 2094 dòng xuống còn 85 dòng khung sườn chuẩn mực.
- [x] Đoạn mã nhúng Web Widget tương đối hóa linh hoạt; quét IP/Hostname tự động 1 chạm.
- [x] Mã nguồn Go trong `pkgs/assistant/` vượt qua `go vet` và kiểm tra đóng gói `go build`.
- [x] Đã gắn tag và phát hành hệ thống `v01.11.00`.
