# 🏗️ Kiến Trúc Hệ Thống Dự Án Assistant (Architecture Blueprint)

**Dự án:** `assistant` (BamOS AI Desktop Copilot & System Companion)  
**Vị trí:** [`/etc/nixos/pkgs/assistant/`](file:///etc/nixos/pkgs/assistant/)  
**Ngôn ngữ cốt lõi:** Go 1.22+ (cgo với GTK3 & WebKitGTK 4.1)  
**Giao diện:** HTML5 / CSS3 / Vanilla JS hiển thị trong suốt qua WebKitGTK  
**Trí tuệ nhân tạo:** Local SLM (`llama-server` port 9090) + Cloud Fallback + Hybrid RAG (SQLite FTS5 + `sqlite-vec` / `chromem-go`)

---

## 1. Triết Lý Thiết Kế & Bối Cảnh Hệ Thống

`assistant` được thiết kế như một **Desktop Copilot siêu nhẹ, luôn sẵn sàng trên góc màn hình Linux**, đóng vai trò cầu nối thông minh giữa người dùng và hệ điều hành NixOS:
- **Tương tác trực quan tự nhiên:** Giao diện desktop pet/widget trong suốt với khả năng kéo thả, ghim cửa sổ (`keep_above`), nhắc nhở nghỉ mắt khoa học (EyeLeo style).
- **Hoạt động bảo mật & Offline-First:** Tận dụng Local LLM chạy trên cổng nội bộ `localhost:9090` kết hợp cơ chế kiểm tra tự khởi động khi cần, tự động hạ nhiệt GPU khi không dùng (NVIDIA RTD3 0W).
- **Khả chuyển & Độc lập:** Có thể build và chạy độc lập từ thư mục `pkgs/assistant/` hoặc đóng gói qua Nix Flake bằng `buildGoModule`.

---

## 2. Mô Hình Kiến Trúc Tổng Thể

```mermaid
graph TD
    User([Người dùng Linux]) -->|Tương tác chuột/phím| GUI[WebKitGTK Frontend Window]
    GUI -->|Custom IPC / JS Message Handler| GoBridge[Go Runtime Engine - gui_linux.go]
    
    subgraph "Go Application Core (pkgs/assistant)"
        GoBridge --> AISvc[AI Service - ai.go]
        GoBridge --> Settings[Settings Manager - settings.go]
        GoBridge --> Waka[WakaTracker - wakatracker.go]
        
        AISvc --> CLI[CLI Engine - cli_engine.go]
        AISvc --> FS[FS Tools - fs_tools.go]
        AISvc --> Inspector[System Inspector - system_inspector.go]
        AISvc --> Profile[User Profile & Persona - user_profile.go]
        AISvc --> RAG[RAG Manager - rag.go]
    end
    
    subgraph "Nền Tảng Hệ Thống & Hạ Tầng"
        RAG --> SQLite[(SQLite Store: FTS5 + sqlite-vec)]
        AISvc --> LlamaSvr[Local llama-server :9090]
        Inspector --> SysFS[/sys & /proc & nvidia-smi]
        CLI --> BashShell[Bash Sandbox / Execution]
    end
```

---

## 3. Phân Rã Chi Tiết Các Module Cốt Lõi

| Tập tin mã nguồn | Vai trò & Trách nhiệm chính |
| :--- | :--- |
| [`main.go`](file:///etc/nixos/pkgs/assistant/main.go) | Điểm vào của chương trình, thiết lập cờ môi trường hiển thị X11/XWayland (`GDK_BACKEND`), tắt tăng tốc DMA-BUF để tránh lỗi màn hình đen trên hybrid GPU NVIDIA, khởi động vòng lặp GTK main loop. |
| [`gui_linux.go`](file:///etc/nixos/pkgs/assistant/gui_linux.go) | Cấu hình cửa sổ GTK3 trong suốt (RGBA visual), nạp WebKitGTK 4.1, thiết lập các JavaScript handler kết nối 2 chiều giữa Go và Webview, quản lý menu khay hệ thống (Tray/Dock), logic cửa sổ bảo vệ mắt. |
| [`ai.go`](file:///etc/nixos/pkgs/assistant/ai.go) | Điều phối luồng xử lý AI: chuẩn hóa message context, kiểm tra và khởi động ngầm `llama-server` khi cần, gọi API chuẩn OpenAI (hỗ trợ Server-Sent Events - SSE streaming), thực thi công cụ (Tool calling). |
| [`rag.go`](file:///etc/nixos/pkgs/assistant/rag.go) | Cơ sở tri thức cục bộ: chỉ mục tài liệu Markdown/Text, tìm kiếm lai (Hybrid Search) kết hợp Full-Text Search (FTS5) và Vector Search (`sqlite-vec` / `chromem-go`). |
| [`system_inspector.go`](file:///etc/nixos/pkgs/assistant/system_inspector.go) | Giám sát trạng thái tài nguyên hệ điều hành: CPU, RAM, nhiệt độ, trạng thái nguồn GPU NVIDIA (Active vs Suspended RTD3), phát hiện tiến trình nghẽn. |
| [`cli_engine.go`](file:///etc/nixos/pkgs/assistant/cli_engine.go) | Động cơ thực thi lệnh CLI an toàn: phân tích câu lệnh, kiểm tra danh sách trắng an toàn (Safety Guard), thông báo kết quả trả về cho LLM. |
| [`fs_tools.go`](file:///etc/nixos/pkgs/assistant/fs_tools.go) | Bộ công cụ thao tác hệ thống tập tin cục bộ: đọc thư mục, đọc file văn bản, tìm kiếm file phục vụ context cho AI. |
| [`wakatracker.go`](file:///etc/nixos/pkgs/assistant/wakatracker.go) | Đếm thời gian làm việc, thống kê năng suất, cảnh báo chu kỳ nghỉ ngơi cho người dùng. |
| [`user_profile.go`](file:///etc/nixos/pkgs/assistant/user_profile.go) | Quản lý thông tin ngữ cảnh người dùng: tên gọi, thói quen, mức độ chi tiết khi trả lời, lịch sử hội thoại dài hạn. |
| [`settings.go`](file:///etc/nixos/pkgs/assistant/settings.go) | Lưu trữ và đồng bộ hóa cấu hình ứng dụng dạng JSON tại `~/.config/bamos/assistant/config.json`. |
| [`frontend/`](file:///etc/nixos/pkgs/assistant/frontend/) | Tài nguyên giao diện HTML, CSS, JavaScript hiển thị trong WebKit webview: các modal cấu hình, chat stream box, hoạt họa mascot 2D. |

---

## 4. Luồng Dữ Liệu Tương Tác Hai Chiều (Webview ⟷ Go Backend)

1. **Từ JavaScript lên Go:**
   - Webview frontend gọi qua cơ chế `window.webkit.messageHandlers.<channel>.postMessage(payload)`.
   - Go bắt sự kiện tại `gui_linux.go` thông qua callback đăng ký với `webkit_user_content_manager_register_script_message_handler`.
2. **Từ Go xuống JavaScript:**
   - Khi có phản hồi stream từ LLM hoặc cập nhật trạng thái hệ thống, Go gọi `webkit_web_view_run_javascript()` để thực thi hàm JS trong trang frontend.
   - Luôn đảm bảo lệnh gọi GTK/WebKit được dispatch trên main thread thông qua hàm tiện ích tương thích luồng an toàn.

---

## 5. Quản Lý Điện Năng & Hạ Tầng Local LLM

- **NVIDIA GPU Power Safety:** Dự án theo dõi sát trạng thái RTD3 (Runtime D3) của card rời. Khi không có tác vụ suy luận AI, quy trình quản lý đảm bảo không đánh thức GPU liên tục để tiết kiệm pin trên laptop.
- **Auto-spawning `llama-server`:** Khi nhận câu hỏi đầu tiên, nếu cổng 9090 chưa lắng nghe, `ai.go` có mutex lock kiểm tra và tự động kích hoạt binary `llama-server` với mô hình GGUF đã cấu hình, sau đó tiến hành streaming response ngay khi service sẵn sàng.

---

## 6. Chiến Lược Đóng Gói Nix Flake

Tập tin [`default.nix`](file:///etc/nixos/pkgs/assistant/default.nix) chịu trách nhiệm đóng gói ứng dụng:
- Sử dụng hàm `buildGoModule` của `nixpkgs`.
- Khai báo đầy đủ `nativeBuildInputs`: `pkg-config`, `wrapGAppsHook3`.
- Khai báo thư viện hệ thống `buildInputs`: `gtk3`, `webkitgtk_4_1`, `sqlite`, `sqlite-vec`.
- Cài đặt file desktop entry `org.bamos.assistant.desktop`, icon hệ thống SVG và Nautilus context script.
