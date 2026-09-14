---
name: plan-agent-workflow
description: Quản lý backlog, lập kế hoạch sprint, sprint review, sprint retrospective, daily scrum và tài liệu kỹ thuật cho dự án troly bằng chuẩn Markdown UI/UX. Kích hoạt khi cần tạo task, cập nhật trạng thái sprint, ghi nhật ký daily, tổ chức review/retro hoặc cập nhật docs.
---

# Mục Tiêu
Quản lý luồng công việc Agile Scrum toàn diện cho dự án `troly` thông qua thư mục [plan/](file:///etc/nixos/pkgs/troly/plan) và đồng bộ hệ thống tài liệu kỹ thuật [docs/](file:///etc/nixos/pkgs/troly/docs).

> 📦 **Bối Cảnh Hệ Thống & Flake Cha:** Dự án `troly` là một **package con** trong hệ thống flake tổng thể tại `/etc/nixos/` (tương tự như `/etc/nixos/pkgs/assistant/` và `/etc/nixos/pkgs/bam/`). Khi nghiệm thu tính năng hoặc hoàn tất Sprint, @PlanAgent giám sát việc @DevOptAgent đóng gói thành công derivation và thực hiện kiểm thử cập nhật hệ thống với lệnh `bam switch` (của package `/etc/nixos/pkgs/bam/`).
> 
> 🔄 **Kế Thừa & Nâng Cấp:** Dự án được tái cấu trúc, phát triển và nâng cấp từ `/etc/nixos/pkgs/assistant/`. Đọc lại toàn bộ thông tin từ dự án cũ và tích hợp, tận dụng các module: Menu thao tác nhanh, các cửa sổ thiết lập (RAG, LLM, System, Waka, Profile), EyeLeo bảo vệ mắt, bối cảnh thư mục vào quy trình quản lý kế hoạch.

# Cây Thư Mục Agile Scrum Chuẩn Trong `/plan/`

```text
plan/
├── README.md                   # Bản đồ tổng quan & chỉ mục liên kết chéo
├── backlog/                    # Yêu cầu sản phẩm & phân rã nghiệp vụ
│   └── BACKLOG.md              # Product Backlog chi tiết (F1 - F7)
├── sprints/                    # Vòng đời các Sprint thực thi
│   └── sprint-XX/              # Thư mục cho từng Sprint (sprint-01, sprint-02,...)
│       ├── PLAN.md             # Kế hoạch & Bảng công việc Sprint XX
│       ├── REVIEW.md           # Đánh giá kết quả bàn giao Sprint XX
│       └── RETRO.md            # Bài học cải tiến quy trình Sprint XX
└── scrum/                      # Hoạt động phối hợp liên Agent
    └── DAILY_SCRUM.md          # Nhật ký Standup hàng ngày (Yesterday - Today - Blockers)
```

### 1. `plan/backlog/BACKLOG.md`
Quản lý danh sách tính năng nghiệp vụ cấp cao (F1 -> F7) và phân rã các User Stories / Tasks.

### 2. `plan/sprints/sprint-XX/PLAN.md` (Sprint Planning & Tracker)
```markdown
# SPRINT XX: <Tên Sprint>
**Thời gian:** DD/MM/YYYY - DD/MM/YYYY | **Trạng thái:** 🟡 IN_PROGRESS | **Phiên bản:** `vAA.BB.CC`

## Mục Tiêu Sprint (Sprint Goal)
- Mô tả mục tiêu trọng tâm cần bàn giao.

## Bảng Công Việc (Sprint Backlog)
| Task ID | Component | Phân loại | Người nhận | Trạng thái | Ghi chú |
|---|---|---|---|---|---|
| `TROLY-101` | NixOS DevEnv | `chore` | @DevOptAgent | 🟢 DONE | Hoàn thành setup |
| `TROLY-102` | Clean Arch | `refactor` | @DevOptAgent | 🟡 IN_PROGRESS | Tách interface |
```

### 3. `plan/sprints/sprint-XX/REVIEW.md` (Sprint Review)
Ghi nhận kết quả chuyển giao, bản demo kỹ thuật, tiêu chí chấp nhận (Acceptance Criteria) và danh sách task spillover sang Sprint kế tiếp.

### 4. `plan/sprints/sprint-XX/RETRO.md` (Sprint Retrospective)
Tổng kết đánh giá 3 trụ cột: Điều làm tốt (Went well), Điểm cần cải thiện (To improve), và Hành động cam kết (Action items gán cụ thể cho Agent).

### 5. `plan/scrum/DAILY_SCRUM.md` (Daily Scrum Tracker)
Nhật ký làm việc hàng ngày của các Agent (@PlanAgent, @RdAgent, @DevOptAgent, @AnimAgent) theo định dạng:
- **Hôm qua:** Công việc đã hoàn thành.
- **Hôm nay:** Kế hoạch thực hiện tiếp theo.
- **Vấn đề (Blockers):** Vướng mắc cần phối hợp giải quyết.

# Quy Trình Điều Phối Tài Liệu `/docs/` & Cấu Trúc File Siêu Nhỏ (Atomic Granularity)
- **Xây dựng hệ thống tập tin Clean Architecture phân nhỏ nhất có thể:** Điều phối chia tách các thư mục và tập tin phù hợp, chuyên nghiệp theo nguyên tắc Single Responsibility.
- **Tiết kiệm AI token tối đa:** Đảm bảo dễ tìm kiếm thư mục, tập tin và nội dung nhỏ nhất khi đọc để tiết kiệm AI token trong toàn bộ quá trình dev.
- **Đồng bộ hệ thống tài liệu chuẩn [docs/](file:///etc/nixos/pkgs/troly/docs):**
  - Khi có thay đổi về kiến trúc, lớp Usecases, Infrastructure, DDL hoặc Mascot: Đồng bộ ngay lập tức vào [docs/ARCHITECTURE.md](file:///etc/nixos/pkgs/troly/docs/ARCHITECTURE.md).
  - Khi có cập nhật về tiêu chuẩn release, git branch hoặc semantic versioning: Đồng bộ vào [docs/GIT_WORKFLOW.md](file:///etc/nixos/pkgs/troly/docs/GIT_WORKFLOW.md).
  - Khi có cập nhật về quy tắc Rules, Skills hoặc tối ưu Context Window: Đồng bộ vào [docs/ANTIGRAVITY_SETUP.md](file:///etc/nixos/pkgs/troly/docs/ANTIGRAVITY_SETUP.md).
  - Duy trì và cập nhật mục lục điều hướng tại [docs/README.md](file:///etc/nixos/pkgs/troly/docs/README.md).
