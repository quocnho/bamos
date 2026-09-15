---
name: assistant-dev-guide
description: Hướng dẫn viết mã nguồn Go 1.22+, cgo/WebKitGTK an toàn luồng, Clean Architecture, SQLite RAG và quản trị tài nguyên hệ thống cho dự án assistant (pkgs/assistant/). Kích hoạt khi viết code Go, sửa lỗi GUI WebKit, tích hợp AI hoặc tối ưu RAG.
---

# Mục Tiêu
Hướng dẫn tiêu chuẩn lập trình Go hiện đại, kiểm soát cgo an toàn với thư viện GTK3/WebKitGTK 4.1, thiết kế kiến trúc sạch (Clean Go Architecture), quản lý bộ nhớ RAG SQLite và giám sát tài nguyên hệ thống cho dự án **`assistant`** (`/etc/nixos/pkgs/assistant/`).

---

# Quy Chuẩn Lập Trình Go 1.22+ & Clean Go Architecture

### 1. Phân Tách Trách Nhiệm & Tránh God Structs
- Mỗi module nghiệp vụ sở hữu một struct chuyên biệt: `AIService`, `RAGManager`, `SystemInspector`, `WakaTracker`, `UserProfileManager`.
- Khởi tạo thông qua Constructor chuẩn Go: `NewAIService(...)`, `NewRAGManager(...)`.
- Tránh tạo biến toàn cục (Global state) không kiểm soát được; truyền tường minh dependencies qua struct fields.

### 2. An Toàn Luồng (Thread-Safety) Khi Tương Tác Cgo / GTK
- **Quy tắc vàng GTK:** Mọi API thay đổi giao diện GTK hoặc WebKitGTK (`webkit_web_view_run_javascript`, `gtk_widget_show`, `gtk_window_move`) **bắt buộc phải chạy trên GTK Main Thread**.
- Khi một Goroutine của Go muốn cập nhật UI (ví dụ: nhận stream token từ `llama-server`):
  - Phải dispatch lời gọi thông qua hàm điều phối tương đương `g_idle_add` hoặc kênh channel an toàn luồng đã bọc trong cgo.
  - Tuyệt đối không gọi trực tiếp con trỏ C GTK từ một goroutine bất kỳ để tránh crash SIGSEGV.

### 3. Quản Lý Goroutine Lifecycle & Context Timeout
- Mọi hàm mạng gọi LLM hoặc đọc ghi đĩa nặng phải nhận `context.Context` (hỗ trợ hủy bỏ khi người dùng nhấn Stop):
  ```go
  func (s *AIService) ChatStream(ctx context.Context, req ChatCompletionReq, callback func(string)) error
  ```
- Sử dụng `sync.Mutex` để đồng bộ hóa trạng thái quan trọng (ví dụ: `startMu` chống khởi động trùng `llama-server`).

### 4. Quy Chuẩn Đường Dẫn Tương Đối & Standalone Portability
- **Không hardcode đường dẫn:** Tuyệt đối không viết cứng `/etc/nixos/pkgs/assistant/...` trong mã nguồn Go hay JavaScript.
- **Xác định đường dẫn tương đối khi runtime:**
  - Đối với cấu hình: Sử dụng `os.UserHomeDir()` kết hợp `~/.config/bamos/assistant/`.
  - Đối với assets tĩnh (`frontend/`): Tìm kiếm tương đối từ thư mục thực thi binary hoặc thư mục `/share/bamos-assistant/` khi cài đặt qua Nix.

### 5. Quản Lý Điện Năng & Tránh Đánh Thức GPU Rời (NVIDIA RTD3 Safety)
- Trong `system_inspector.go`:
  - Kiểm tra trạng thái `/sys/bus/pci/devices/.../power/runtime_status` trước khi gọi các lệnh nặng như `nvidia-smi`.
  - Nếu GPU đang ở trạng thái `suspended` (RTD3 0W), không được chạy lệnh gây đánh thức card rời vô nghĩa.

---

# Quy Chuẩn Git Commit (Why - What - Test)
Khi hoàn tất chỉnh sửa, tuân thủ đúng chuẩn theo [docs/assistant/GIT_WORKFLOW.md](file:///etc/nixos/docs/assistant/GIT_WORKFLOW.md):

```text
<type>(AST-<ID>): <short summary> [vAA.BB.CC]

[WHY / BUSINESS CONTEXT]
- Lý do thực hiện thay đổi, bối cảnh bài toán và nguyên nhân gốc.

[WHAT / SCOPE OF CHANGE]
- Tóm tắt các file và hàm Go/Webview được can thiệp.

[TEST / DEFINITION OF DONE]
- [x] go fmt & go vet pass.
- [x] go test pass.
- [x] Đã chạy thử ứng dụng không lỗi hiển thị WebKit.
- [x] Kiểm thử build nix package / bam switch.
```
