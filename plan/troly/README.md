# BẢN ĐỒ KẾ HOẠCH DỰ ÁN TROLY (PROJECT ROADMAP & PLAN INDEX)

Chào mừng đến với hệ thống quản trị Agile Scrum của dự án Native Edge AI Desktop **`troly`**.

> 🔄 **Nguồn gốc & Kế thừa:** Dự án `troly` được tái cấu trúc, phát triển và nâng cấp từ `/etc/nixos/pkgs/assistant/`. Toàn bộ thông tin, nghiệp vụ và tính năng từ dự án `assistant` (hệ thống Menu, các cửa sổ thiết lập RAG/LLM/System/Waka/Profile, cơ chế bảo vệ sức khỏe EyeLeo, bối cảnh thư mục...) được nghiên cứu đầy đủ và bổ sung vào kiến trúc `troly` dưới chuẩn C++20/Qt6 Native.

---

## 🗺️ Cây Thư Mục Quản Trị `plan/troly/`

```text
plan/troly/
├── README.md                   # Chỉ mục điều hướng & bản đồ tổng quan của dự án troly
├── backlog/                    # Yêu cầu sản phẩm & phân rã tính năng
│   └── BACKLOG.md              # Product Backlog chi tiết (F1 - F7)
├── sprints/                    # Vòng đời các Sprint thực thi
│   ├── sprint-01/              # Sprint 01: Core Architecture & Setup
│   │   ├── PLAN.md             # Kế hoạch & Bảng công việc Sprint 01
│   │   ├── REVIEW.md           # Đánh giá kết quả bàn giao Sprint 01
│   │   └── RETRO.md            # Bài học cải tiến quy trình Sprint 01
│   └── ...                     # Các Sprint tiếp theo (sprint-02, sprint-03,...)
└── scrum/                      # Hoạt động phối hợp liên Agent
    └── DAILY_SCRUM.md          # Nhật ký làm việc hàng ngày (Standup Log)
```

---

## 📌 Liên Kết Nhanh (Quick Links)

| Phân khu | Tài liệu trọng tâm | Mô tả | Trạng thái |
|---|---|---|---|
| **Backlog** | [BACKLOG.md](file:///etc/nixos/plan/troly/backlog/BACKLOG.md) | Phân rã 7 nhóm tính năng lớn F1 - F7 | 🟢 SẴN SÀNG |
| **Sprint Hiện Tại** | [sprint-01/PLAN.md](file:///etc/nixos/plan/troly/sprints/sprint-01/PLAN.md) | Kế hoạch Sprint 01 (`v01.01.00`) | 🟡 IN_PROGRESS |
| **Sprint Review** | [sprint-01/REVIEW.md](file:///etc/nixos/plan/troly/sprints/sprint-01/REVIEW.md) | Đánh giá chuyển giao Sprint 01 | 🟡 DRAFT |
| **Sprint Retro** | [sprint-01/RETRO.md](file:///etc/nixos/plan/troly/sprints/sprint-01/RETRO.md) | Đánh giá năng suất & hành động | 🟡 IN_PROGRESS |
| **Daily Scrum** | [DAILY_SCRUM.md](file:///etc/nixos/plan/troly/scrum/DAILY_SCRUM.md) | Nhật ký hàng ngày của các AI Agent | 🟢 ACTIVE |

---

## 🔗 Liên Kết Hệ Thống
- 🏗️ **Tài liệu kiến trúc kỹ thuật:** [docs/troly/ARCHITECTURE.md](file:///etc/nixos/docs/troly/ARCHITECTURE.md)
- 🌿 **Quy chuẩn Git & DoD:** [docs/troly/GIT_WORKFLOW.md](file:///etc/nixos/docs/troly/GIT_WORKFLOW.md)
- ⚙️ **Quy chuẩn Agent Harness:** [docs/troly/ANTIGRAVITY_SETUP.md](file:///etc/nixos/docs/troly/ANTIGRAVITY_SETUP.md)
- 🗺️ **Kế hoạch tổng thể hệ thống:** [plan/README.md](file:///etc/nixos/plan/README.md)

---

## 👥 Ma Trận Trách Nhiệm (RACI Matrix)

- **@PlanAgent:** Quản trị toàn bộ cấu trúc `plan/troly/`, cập nhật tiến độ Sprint, điều phối Review/Retro và Daily Scrum.
- **@RdAgent:** Đánh giá trade-off kỹ thuật, cập nhật giải pháp cho các ticket spike trong Sprint.
- **@DevOptAgent:** Nhận ticket, thực thi C++20 Clean Architecture, chạy kiểm thử và cập nhật Definition of Done (DoD).
- **@AnimAgent:** Chỉ đạo nghệ thuật nhân vật Mascot, chuẩn hóa animation 12 nguyên tắc Disney, FSM state và pipeline 3D.
