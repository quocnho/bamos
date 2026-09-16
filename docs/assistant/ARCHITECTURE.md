# 🏗️ Kiến Trúc Hệ Thống Dự Án Assistant (Architecture Blueprint)

**Dự án:** `assistant` (BamOS AI Desktop Copilot & System Companion)  
**Vị trí:** [`/etc/nixos/pkgs/assistant/`](file:///etc/nixos/pkgs/assistant/)  
**Ngôn ngữ cốt lõi:** Go 1.22+ (cgo với GTK3 & WebKitGTK 4.1)  
**Giao diện:** HTML5 / CSS3 / Vanilla JS (ES Modules + Templates phân rã) hiển thị trong suốt qua WebKitGTK  
**Trí tuệ nhân tạo:** Local SLM (`llama-server` port 9090) với Auto-Recovery + Cloud Fallback + Hybrid RAG (SQLite FTS5 + `sqlite-vec` / `chromem-go`)  
**Khả năng mở rộng:** Web Widget Studio & Domain Whitelist (tương tự Live Helper Chat / Intercom), tự động quét IP/tên miền để sinh mã nhúng linh hoạt.

---

## 1. Triết Lý Thiết Kế & Bối Cảnh Hệ Thống

`assistant` được thiết kế như một **Desktop Copilot siêu nhẹ, luôn sẵn sàng trên góc màn hình Linux**, đồng thời hoạt động như một **Web Copilot Server** cho phép nhúng vào mọi website:
* **Giao tiếp Frontend-Backend chuẩn Wails v3 IPC:** Tích hợp `window.wails` bridge giả lập chuẩn Wails v3 với `Call(method, ...args)` và `Events.On(name, cb)` / `Emit(name, data)` cho phép điều khiển backend hai chiều mượt mà.
- **Neo chuẩn 4 góc màn hình (4-Corner Screen Docking):** Loại bỏ hoàn toàn cơ chế kéo thả tự do gây xung đột Wayland/XWayland. Cửa sổ cố định vững chắc tại 4 góc (`bottom-right`, `bottom-left`, `top-right`, `top-left`) tính toán theo `get_workarea()`.
- **Hệ thống Đa Linh Vật (Multi-Mascot Vector Engine):** Hỗ trợ chuyển đổi 4 thú cưng trong thời gian thực: Chó con (Puppy), Mèo con (Cat), Thỏ ngọc (Rabbit), và Ông Bụt / Phù thủy (Wizard) với bộ khung SVG đồng nhất lớp mắt và miệng cho animation.
- **Phân rã module siêu hạt nhỏ (Atomic Granularity):** Toàn bộ giao diện frontend được module hóa: file `index.html` chỉ giữ khung sườn 85 dòng, CSS phân tầng trong `frontend/css/{base,components,modals}`, và các template HTML độc lập trong `frontend/templates/` nạp động qua `template-loader.js`.
- **Hoạt động bảo mật, Offline-First & Auto-Recovery:** Tận dụng Local LLM chạy trên cổng nội bộ `localhost:9090`. Khi client gửi câu hỏi nếu `llama-server` bị gián đoạn hoặc zombie `<defunct>`, hệ thống tự động dọn dẹp tiến trình, kích hoạt lại AI server và khôi phục luồng stream mà không bị treo vô hạn.
- **Web Widget Studio & Network IP Scanner:** Tích hợp HTTP Server nội bộ (mặc định cổng `9195`) phục vụ Web Widget qua SSE `/api/chat/stream`, hỗ trợ CORS, cơ chế quét card mạng tự động phát hiện IP/Hostname máy tính (`/api/system/network-addresses`) và quản lý danh sách trắng Domain (Domain Whitelist).

---

## 2. Mô Hình Kiến Trúc Tổng Thể

```mermaid
graph TD
    UserDesktop([Người dùng Linux Desktop]) -->|Tương tác chuột/phím| GUI[WebKitGTK Frontend Window]
    UserWeb([Khách truy cập Web / LAN]) -->|Iframe Widget| Widget[Web Widget Embed :9195]
    
    GUI -->|Wails v3 IPC: window.wails.Call / Events| GoBridge[Go Runtime Engine - gui_linux.go]
    Widget -->|SSE /api/chat/stream & CORS| GoBridge
    
    subgraph "Go Application Core (pkgs/assistant)"
        GoBridge --> DockEng[4-Corner Dock Engine: BR, BL, TR, TL]
        GoBridge --> AISvc[AI Service - ai.go (Auto-Recovery)]
        GoBridge --> Settings[Settings Manager - settings.go]
        GoBridge --> Waka[WakaTracker - wakatracker.go]
        GoBridge --> NetScan[Network Scanner - settings.go]
        
        AISvc --> CLI[CLI Engine - cli_engine.go]
        AISvc --> FS[FS Tools - fs_tools.go]
        AISvc --> Inspector[System Inspector - system_inspector.go]
        AISvc --> Profile[User Profile & Persona - user_profile.go]
        AISvc --> RAG[RAG Manager - rag.go]
    end
    
    subgraph "Nền Tảng Hệ Thống & Hạ Tầng"
        RAG --> SQLite[(SQLite Store: FTS5 + sqlite-vec)]
        AISvc --> LlamaSvr[Local llama-server :9090 (Reap Child Process)]
        Inspector --> SysFS[/sys & /proc & nvidia-smi]
        CLI --> BashShell[Bash Sandbox / Execution]
        NetScan --> NetIF[net.Interfaces & os.Hostname]
    end
```

---

## 3. Phân Rã Chi Tiết Các Module Cốt Lõi

| Tập tin / Thư mục | Vai trò & Trách nhiệm chính |
| :--- | :--- |
| [`main.go`](file:///etc/nixos/pkgs/assistant/main.go) | Điểm vào chương trình, thiết lập cờ môi trường hiển thị X11/XWayland (`GDK_BACKEND`), tắt tăng tốc DMA-BUF tránh màn hình đen trên hybrid GPU NVIDIA, khởi động vòng lặp GTK main loop. |
| [`gui_linux.go`](file:///etc/nixos/pkgs/assistant/gui_linux.go) | Cấu hình cửa sổ GTK3 trong suốt (RGBA visual), nạp WebKitGTK 4.1/6.0, Wails v3 IPC runtime shim, quản lý neo 4 góc màn hình (`BR`, `BL`, `TR`, `TL`), HTTP mux server phục vụ API nội bộ & Web Widget. |
| [`ai.go`](file:///etc/nixos/pkgs/assistant/ai.go) | Điều phối luồng xử lý AI: chuẩn hóa message context, dọn dẹp tiến trình zombie (`pkill` + reap child process qua goroutine `Wait`), cơ chế Auto-Recovery tự phát hiện và khởi động `llama-server` khi offline, SSE streaming response. |
| [`settings.go`](file:///etc/nixos/pkgs/assistant/settings.go) | Lưu trữ và đồng bộ hóa cấu hình JSON tại `~/.config/bamos/assistant/config.json`; cung cấp bộ quét IP card mạng và tên miền máy tính (`handleGetNetworkAddresses`). |
| [`config.go`](file:///etc/nixos/pkgs/assistant/config.go) | Cấu trúc dữ liệu cấu hình Runtime (`Config`), thiết lập giao diện (`DockPosition`, `WindowScale`, `MascotType`), nhúng Web Widget (`WidgetConfig`) và quản lý kiểm tra danh sách trắng domain (`IsOriginAllowed`). |
| [`rag.go`](file:///etc/nixos/pkgs/assistant/rag.go) | Cơ sở tri thức cục bộ: chỉ mục tài liệu Markdown/Text, tìm kiếm lai (Hybrid Search) kết hợp Full-Text Search (FTS5) và Vector Search (`sqlite-vec` / `chromem-go`). |
| [`system_inspector.go`](file:///etc/nixos/pkgs/assistant/system_inspector.go) | Giám sát trạng thái tài nguyên hệ điều hành: CPU, RAM, nhiệt độ, trạng thái nguồn GPU NVIDIA (Active vs Suspended RTD3), phát hiện tiến trình nghẽn. |
| [`cli_engine.go`](file:///etc/nixos/pkgs/assistant/cli_engine.go) | Động cơ thực thi lệnh CLI an toàn: phân tích câu lệnh, kiểm tra danh sách trắng an toàn (Safety Guard), thông báo kết quả trả về lời nhắc AI. |
| [`frontend/`](file:///etc/nixos/pkgs/assistant/frontend/) | Mã nguồn giao diện WebKitGTK module hóa: CSS phân tầng (`css/base/`, `css/components/`, `css/modals/`), JavaScript kiến trúc hướng module (`js/core/wails-bridge.js`, `js/mascot/`, `js/features/appearance/`). |
| [`frontend/templates/`](file:///etc/nixos/pkgs/assistant/frontend/templates/) | Các thành phần giao diện tách rời: `mascot-puppy.html`, `chat-bubble.html`, thư mục `eyeleo/`, thư mục `modals/` (đã bổ sung `modal-appearance.html`). |

---

## 4. Cơ Chế Nhúng Web Widget & Quét Mạng Tự Động

1. **Khả năng tương đối hóa `baseUrl` (`frontend/embed.js`):**
   - Không gán cứng địa chỉ máy chủ. Tự động bóc tách `origin` từ đường dẫn `<script src="...">` đang nhúng.
   - Hỗ trợ ghi đè qua thuộc tính `data-base-url="..."` hoặc biến toàn cục `window.__BAMOS_ASSISTANT_BASE_URL__`.
   - Fallback an toàn về `window.location.origin` hoặc hostname máy.
2. **Quét phát hiện IP/Hostname (`/api/system/network-addresses`):**
   - Go backend duyệt qua `net.Interfaces()` và `os.Hostname()`, lọc ra các địa chỉ IP IPv4 hoạt động (Wi-Fi, Ethernet, VPN) và hostname `.local`.
   - Frontend Studio hiển thị danh sách chip 1-click: khi người dùng click vào IP bất kỳ, hệ thống cập nhật tức thì đoạn mã nhúng sinh ra và tự động mở Binding Host sang `0.0.0.0` nếu là mạng LAN.
3. **Bảo mật Whitelist Domain (CORS Guard):**
   - Hỗ trợ so khớp chính xác (`https://example.com`) hoặc ký tự đại diện (`*.example.local`, `http://localhost:*`).

---

## 5. Quản Lý Điện Năng & Tự Phục Hồi AI Engine

- **Chống treo tiến trình Zombie:** Sử dụng goroutine `server.Wait()` để tự động thu hồi tài nguyên tiến trình con của `llama-server`, dọn dẹp các instance `<defunct>` tồn đọng sau khi crash.
- **Auto-Recovery Khi Chat:** Nếu server AI cục bộ chưa sẵn sàng khi người dùng gửi câu hỏi, hệ thống gửi thông báo thân thiện *"Em đang khởi động động cơ AI cục bộ..."*, tự động trigger khởi chạy server, kiểm tra `/health` và khôi phục luồng stream mà không bắt người dùng phải khởi động lại trợ lý thủ công.
- **Bảo toàn chế độ tiết kiệm điện NVIDIA RTD3 0W:** Khi không có tác vụ suy luận, trợ lý không đánh thức GPU card rời liên tục.

---

## 6. Chiến Lược Đóng Gói Nix Flake & Standalone Portability

Tập tin [`default.nix`](file:///etc/nixos/pkgs/assistant/default.nix) chịu trách nhiệm đóng gói ứng dụng:
- Sử dụng hàm `buildGoModule` của `nixpkgs`, hỗ trợ cơ chế `//go:embed frontend` tích hợp toàn bộ HTML templates, JS, CSS vào trong binary duy nhất.
- Khai báo đầy đủ `nativeBuildInputs`: `pkg-config`, `wrapGAppsHook3`.
- Khai báo thư viện hệ thống `buildInputs`: `gtk3`, `webkitgtk_4_1`, `sqlite`.
- Cài đặt desktop entry `org.bamos.assistant.desktop`, icon hệ thống SVG và Nautilus context script `nautilus-bone-context.sh`.

