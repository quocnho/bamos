# 📝 Nhật Ký Daily Standup Dự Án Assistant

Tài liệu này ghi nhận nhật ký làm việc hàng ngày của các AI Agent và lập trình viên tham gia phát triển gói phần mềm **`assistant`** theo mô hình Agile Scrum:
- **Hôm qua (Yesterday):** Công việc đã hoàn thành.
- **Hôm nay (Today):** Công việc dự kiến thực hiện.
- **Vướng mắc (Blockers):** Khó khăn hoặc điểm cần phối hợp.

---

## 📅 Nhật Ký Ngày: 15/09/2026

### 🎯 Phối Hợp Liên Agent
- **Đại diện điều phối:** `@AssistantPlanAgent`
- **Kỹ sư thực thi:** `@AssistantDevAgent`

#### 1. `@AssistantPlanAgent`
- **Hôm qua:** Hoàn tất khởi tạo toàn bộ cây tài liệu kỹ thuật tại [docs/assistant/](file:///etc/nixos/docs/assistant/) và Agile Scrum [plan/assistant/](file:///etc/nixos/plan/assistant/).
- **Hôm nay:**
  - Cập nhật tài liệu kiến trúc [ARCHITECTURE.md](file:///etc/nixos/docs/assistant/ARCHITECTURE.md): phân rã chi tiết kiến trúc Web Widget Studio, bộ quét mạng IP/Hostname, cơ chế Auto-Recovery AI engine và cấu trúc templates frontend nạp động.
  - Đồng bộ hóa Sprint 01 hoàn thành xuất sắc (`v0.3.1`), cập nhật [BACKLOG.md](file:///etc/nixos/plan/assistant/backlog/BACKLOG.md) và [PLAN.md](file:///etc/nixos/plan/assistant/sprints/sprint-01/PLAN.md).
  - Phối hợp gắn Release Tag `v01.11.00` và push lên GitHub.
- **Vướng mắc:** Không có.

#### 2. `@AssistantDevAgent`
- **Hôm qua:** Duy trì mã nguồn Go, tích hợp xử lý lỗi màn hình đen trên XWayland/NVIDIA trong `main.go`.
- **Hôm nay:**
  - [AST-110]: Xóa bỏ giới hạn cứng `MAX_FIT_HEIGHT`, mở rộng vùng làm việc tối đa không giới hạn kích thước; neo góc dưới bên phải cố định (`g_fit_x = right - w, g_fit_y = bottom - h`) giúp chú cún mascot không bao giờ bị lệch vị trí.
  - [AST-111]: Triệt tiêu tiến trình zombie `<defunct>` của `llama-server` (dọn dẹp tiến trình tồn đọng + thu hồi child process qua goroutine `Wait`), bổ sung cơ chế Auto-Recovery tự kiểm tra `/health` và khởi động lại AI server khi stream chat nếu bị gián đoạn.
  - [AST-112]: Phân rã `index.html` từ 2.094 dòng xuống còn 85 dòng khung sườn, tách 14 HTML templates vào thư mục `frontend/templates/` (`chat-bubble`, `mascot-puppy`, `eyeleo/`, `modals/`) và nạp tự động qua `template-loader.js`.
  - [AST-113]: Xây dựng Web Widget Studio & Domain Whitelist, tương đối hóa `baseUrl` trong `embed.js`, phát triển API quét IP/Hostname (`/api/system/network-addresses`), bổ sung chip 1-click chọn IP và tự động cập nhật mã nhúng theo IP và cổng cấu hình.
  - Kiểm thử `go vet ./...` và `go build` thành công 100%.
- **Vướng mắc:** Không có. Codebase hoạt động trơn tru, tài nguyên tĩnh được embed an toàn qua `//go:embed`.
