---
name: assistant-plan-workflow
description: Quản lý backlog, lập kế hoạch sprint, sprint review, sprint retrospective, daily scrum và tài liệu kỹ thuật cho dự án assistant (pkgs/assistant/) bằng chuẩn Markdown UI/UX. Kích hoạt khi cần tạo task AST, cập nhật trạng thái sprint, ghi nhật ký daily hoặc cập nhật docs assistant.
---

# Mục Tiêu
Quản lý luồng công việc Agile Scrum chuyên nghiệp cho dự án **`assistant`** (Go + WebKitGTK AI Desktop Copilot) thông qua cây thư mục [plan/assistant/](file:///etc/nixos/plan/assistant/) và đồng bộ hệ thống tài liệu kỹ thuật [docs/assistant/](file:///etc/nixos/docs/assistant/).

> 📦 **Bối Cảnh Hệ Thống & Flake Cha:** Dự án `assistant` là một **package con** trong hệ thống flake tổng thể tại `/etc/nixos/` (`pkgs/assistant/`). Khi hoàn tất task hoặc nghiệm thu Sprint, `@AssistantPlanAgent` theo dõi việc đóng gói thành công derivation với Nix và kiểm thử cập nhật hệ thống thông qua `bam switch` (hoặc `bam dry`).

---

# Cây Thư Mục Agile Scrum Chuẩn Trong `/plan/assistant/`

```text
plan/
└── assistant/                  # Hồ sơ Agile Scrum của package assistant
    ├── README.md               # Bản đồ tổng quan & chỉ mục liên kết chéo
    ├── backlog/                # Yêu cầu sản phẩm & phân rã nghiệp vụ
    │   └── BACKLOG.md          # Product Backlog chi tiết (AST-F1 -> AST-F6)
    ├── sprints/                # Vòng đời các Sprint thực thi
    │   └── sprint-XX/          # Thư mục cho từng Sprint (sprint-01, sprint-02,...)
    │       ├── PLAN.md         # Kế hoạch & Bảng công việc Sprint XX
    │       ├── REVIEW.md       # Đánh giá kết quả bàn giao Sprint XX
    │       └── RETRO.md        # Bài học cải tiến quy trình Sprint XX
    └── scrum/                  # Hoạt động phối hợp liên Agent
        └── DAILY_SCRUM.md      # Nhật ký Standup hàng ngày (Yesterday - Today - Blockers)
```

---

# Quy Trình Thao Tác Của `@AssistantPlanAgent`

### 1. Tạo Task Mới Vào Backlog (`plan/assistant/backlog/BACKLOG.md`)
- Sử dụng mã định danh thống nhất: **`AST-<số>`** (Ví dụ: `AST-110`).
- Phân loại rõ Domain:
  - `AST-F1`: Core Go Runtime & GTK/WebKit Window
  - `AST-F2`: Local LLM / llama-server Orchestration
  - `AST-F3`: Hybrid RAG (SQLite FTS5 + Vector)
  - `AST-F4`: System Inspector & Hardware Telemetry (NVIDIA RTD3)
  - `AST-F5`: Webview UI/UX & Nautilus Integration
  - `AST-F6`: Productivity, WakaTracker & Eye-care

### 2. Quản Trị Sprint (`plan/assistant/sprints/sprint-XX/PLAN.md`)
- Cập nhật bảng công việc Sprint:
  - `Task ID` | `Thành phần` | `Loại việc` | `Người nhận` | `Trạng thái` (`🟢 DONE`, `🟡 IN_PROGRESS`, `⚪ TODO`) | `Ghi chú`
- Đảm bảo kiểm tra tiêu chí nghiệm thu (DoD) trước khi chuyển trạng thái sang `🟢 DONE`.

### 3. Cập Nhật Daily Standup (`plan/assistant/scrum/DAILY_SCRUM.md`)
- Ghi lại nhật ký theo 3 ý chính:
  - **Hôm qua:** Những task `AST-xxx` nào đã xong hoặc tiến triển.
  - **Hôm nay:** Kế hoạch thực hiện task tiếp theo của `@AssistantPlanAgent` và `@AssistantDevAgent`.
  - **Vướng mắc (Blockers):** Lỗi thư viện cgo, xung đột hiển thị WebKit, hoặc cấu hình Nix cần hỗ trợ.
