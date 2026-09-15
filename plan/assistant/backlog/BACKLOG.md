# 📋 Danh Mục Yêu Cầu Tính Năng (Product Backlog - Assistant)

Tài liệu này quản lý toàn bộ các tính năng, cải tiến kỹ thuật và nợ kỹ thuật (Technical Debt) của dự án **`assistant`** theo các miền nghiệp vụ lớn.

---

## 🧭 Phân Loại Miền Nghiệp Vụ (Domains)

- **`AST-F1`**: Core Go Runtime, GTK3 Window & WebKitGTK Lifecycle (Cửa sổ trong suốt, X11/XWayland, ghim cửa sổ).
- **`AST-F2`**: AI Engine, Local LLM Orchestration & Streaming (SSE, Auto-start llama-server port 9090, Tool calling).
- **`AST-F3`**: Hybrid RAG & Tri thức cục bộ (SQLite FTS5, `sqlite-vec`, `chromem-go`, chia nhỏ văn bản).
- **`AST-F4`**: System Inspector & Telemetry (Nhiệt độ CPU/RAM, NVIDIA RTD3 0W power safety, tiến trình).
- **`AST-F5`**: Webview UI/UX & Tương tác hai chiều (Giao diện bong bóng chat, Nautilus context menu script, phím tắt).
- **`AST-F6`**: Năng suất & Bảo vệ sức khỏe (WakaTracker, Eye-care break, Pomodoro).

---

## 📌 Danh Sách Task / User Stories Chi Tiết

| Ticket ID | Miền | Tiêu Đề / Nội Dung Kỹ Thuật | Độ Ưu Tiên | Trạng Thái | Sprint |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `AST-101` | `AST-F1` | Hoàn thiện tài liệu kiến trúc, Git workflow & thiết lập Agile Scrum | P0 | 🟢 **DONE** | Sprint 01 |
| `AST-102` | `AST-F1` | Thiết lập bộ Agent Skills & Rules chuyên trách cho Go/WebKitGTK | P0 | 🟢 **DONE** | Sprint 01 |
| `AST-103` | `AST-F1` | Tối ưu hóa cờ hiển thị tránh màn hình đen WebKit trên hybrid GPU Intel/NVIDIA | P1 | 🟢 **DONE** | Sprint 01 |
| `AST-110` | `AST-F1` | Loại bỏ giới hạn kích thước cửa sổ MAX_FIT_HEIGHT, mở rộng toàn màn hình và neo cố định góc dưới bên phải cho pet | P0 | 🟢 **DONE** | Sprint 01 |
| `AST-111` | `AST-F2` | Khắc phục lỗi treo LLM do tiến trình zombie `<defunct>` bằng Auto-Recovery và thu hồi child process | P0 | 🟢 **DONE** | Sprint 01 |
| `AST-112` | `AST-F5` | Module hóa index.html thành cấu trúc thư mục templates/ chuyên nghiệp nạp qua template-loader.js | P1 | 🟢 **DONE** | Sprint 01 |
| `AST-113` | `AST-F5` | Xây dựng Web Widget Studio, tương đối hóa baseUrl và quét tự động card mạng IP/Hostname máy tính | P0 | 🟢 **DONE** | Sprint 01 |
| `AST-104` | `AST-F3` | Nâng cấp cơ chế phân đoạn văn bản và tối ưu hybrid query (FTS5 + vector) | P1 | 🟡 **IN_PROGRESS** | Sprint 02 |
| `AST-105` | `AST-F4` | Hoàn thiện cơ chế giám sát RTD3 GPU để không vô tình đánh thức card NVIDIA rời | P1 | 🟡 **IN_PROGRESS** | Sprint 02 |
| `AST-106` | `AST-F2` | Cải thiện cơ chế Auto-start llama-server và xử lý timeout khi cold-boot | P2 | ⚪ **TODO** | Sprint 02 |
| `AST-107` | `AST-F5` | Chuẩn hóa kịch bản Nautilus context script gửi thư mục vào trợ lý | P2 | ⚪ **TODO** | Sprint 02 |
| `AST-108` | `AST-F6` | Đồng bộ cấu hình WakaTracker và Eye-care reminder trong giao diện Settings | P2 | ⚪ **TODO** | Sprint 02 |
| `AST-109` | `AST-F1` | Tách phân rã cấu trúc file `main.go` và `gui_linux.go` theo hướng Clean Architecture | P3 | ⚪ **BACKLOG** | TBD |

---

## 🏷️ Quy Ước Mức Độ Ưu Tiên
- **P0 (Critical / Blocker):** Các thành phần cốt lõi của kiến trúc, tài liệu chuẩn và hạ tầng build bắt buộc.
- **P1 (High):** Trải nghiệm hiển thị, an toàn phần cứng (GPU power) và tính đúng đắn của RAG.
- **P2 (Medium):** Tính năng tiện ích người dùng, tích hợp Nautilus, đồng bộ cấu hình.
- **P3 (Low):** Tái cấu trúc mã nguồn sâu, dọn dẹp nợ kỹ thuật.
