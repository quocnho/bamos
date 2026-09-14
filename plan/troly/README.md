# BẢN ĐỒ KẾ HOẠCH DỰ ÁN TROLY (PROJECT ROADMAP & PLAN INDEX)

Chào mừng đến với hệ thống quản trị Agile Scrum của dự án Native Edge AI Desktop **`troly`**.

> 🔄 **Nguồn gốc & Kế thừa:** Dự án `troly` được tái cấu trúc, phát triển và nâng cấp từ `/etc/nixos/pkgs/assistant/`. Toàn bộ thông tin, nghiệp vụ và tính năng từ dự án `assistant` (hệ thống Menu, các cửa sổ thiết lập RAG/LLM/System/Waka/Profile, cơ chế bảo vệ sức khỏe EyeLeo, bối cảnh thư mục...) được nghiên cứu đầy đủ và bổ sung vào kiến trúc `troly` dưới chuẩn C++20/Qt6 Native.

---

## 🗺️ Cây Thư Mục Quản Trị `plan/troly/`

```text
plan/troly/
├── README.md                   # Chỉ mục điều hướng & bản đồ tổng quan của dự án troly
├── backlog/                    # Yêu cầu sản phẩm & phân rã tính năng
│   └── BACKLOG.md              # Master Product Backlog & Lộ trình phân kỳ Milestones (F1 - F8)
├── sprints/                    # Vòng đời các Sprint thực thi
│   ├── sprint-01/              # Sprint 01: Core Architecture & Setup (🟢 COMPLETED - v01.01.00)
│   ├── sprint-02/              # Sprint 02: Modern Mascot UI & EyeLeo Native (🟢 COMPLETED - v01.02.00)
│   │   ├── PLAN.md             # Kế hoạch & Bảng công việc Sprint 02
│   │   ├── REVIEW.md           # Đánh giá kết quả bàn giao Sprint 02
│   │   └── RETRO.md            # Bài học cải tiến quy trình Sprint 02
│   ├── sprint-03/              # Sprint 03: Vector RAG & SQLite WAL Engine (🟢 COMPLETED - v01.03.00)
│   │   ├── PLAN.md             # Kế hoạch & Bảng công việc Sprint 03
│   │   ├── REVIEW.md           # Đánh giá kết quả bàn giao Sprint 03
│   │   └── RETRO.md            # Bài học cải tiến quy trình Sprint 03
│   ├── sprint-04/              # Sprint 04: Local Inference & Dynamic MoE Router (🟢 COMPLETED - v01.04.00)
│   │   ├── PLAN.md             # Kế hoạch & Bảng công việc Sprint 04
│   │   ├── REVIEW.md           # Đánh giá kết quả bàn giao Sprint 04
│   │   └── RETRO.md            # Bài học cải tiến quy trình Sprint 04
│   ├── sprint-05/              # Sprint 05: Action Dispatcher & Safety Guard (🟢 COMPLETED - v01.05.00)
│   │   ├── PLAN.md             # Kế hoạch & Bảng công việc Sprint 05
│   │   ├── REVIEW.md           # Đánh giá kết quả bàn giao Sprint 05
│   │   └── RETRO.md            # Bài học cải tiến quy trình Sprint 05
│   └── ...                     # Các Sprint tiếp theo (sprint-06 ➔ sprint-07)
└── scrum/                      # Hoạt động phối hợp liên Agent
    └── DAILY_SCRUM.md          # Nhật ký làm việc hàng ngày (Standup Log)
```

---

## 📌 Liên Kết Nhanh (Quick Links)

| Phân khu | Tài liệu trọng tâm | Mô tả | Trạng thái |
|---|---|---|---|
| **Master Backlog** | [BACKLOG.md](file:///etc/nixos/plan/troly/backlog/BACKLOG.md) | Bức tranh sản phẩm hoàn chỉnh & Master Roadmap F1 - F8 | 🟢 HOÀN THIỆN |
| **Sprint 01 (Nền Tảng)** | [sprint-01/PLAN.md](file:///etc/nixos/plan/troly/sprints/sprint-01/PLAN.md) | Khởi tạo Clean Arch, NixOS Flake & Build system (`v01.01.00`) | 🟢 COMPLETED |
| **Sprint 02 (Mascot & EyeLeo)** | [sprint-02/PLAN.md](file:///etc/nixos/plan/troly/sprints/sprint-02/PLAN.md) | Mascot Peek Tail & EyeLeo Native C++ (`v01.02.00`) | 🟢 COMPLETED |
| **Sprint 03 (Vector RAG)** | [sprint-03/PLAN.md](file:///etc/nixos/plan/troly/sprints/sprint-03/PLAN.md) | Động cơ tri thức SQLite WAL & sqlite-vec RRF (`v01.03.00`) | 🟢 COMPLETED |
| **Sprint 04 (MoE & Inference)**| [sprint-04/PLAN.md](file:///etc/nixos/plan/troly/sprints/sprint-04/PLAN.md) | Suy luận SSE, Intent Classifier <30ms, MoE Router (`v01.04.00`) | 🟢 COMPLETED |
| **Sprint 05 (Action & Safety)**| [sprint-05/PLAN.md](file:///etc/nixos/plan/troly/sprints/sprint-05/PLAN.md) | Dispatcher, Safety Guard 4 cấp độ, Human-in-the-Loop (`v01.05.00`) | 🟢 COMPLETED |
| **Sprint 06 (System & Persona)**| [sprint-06/PLAN.md](file:///etc/nixos/plan/troly/sprints/sprint-06/PLAN.md) | System Inspector, WakaTracker & Adaptive Persona (`v01.06.00`) | 🟢 COMPLETED |
| **Sprint 06 Review** | [sprint-06/REVIEW.md](file:///etc/nixos/plan/troly/sprints/sprint-06/REVIEW.md) | Nghiệm thu 7/7 Tasks hoàn tất 100% CTest (5/5) & Nix build | 🟢 PASSED |
| **Sprint 07 (Self-Evolving & 3D)**| [sprint-07/PLAN.md](file:///etc/nixos/plan/troly/sprints/sprint-07/PLAN.md) | Self-Evolving Hub, LoRA Pipeline & 3D Mascot POC (`v01.07.00`) | 🟢 COMPLETED |
| **Sprint 07 Review** | [sprint-07/REVIEW.md](file:///etc/nixos/plan/troly/sprints/sprint-07/REVIEW.md) | Nghiệm thu F1-F8, 6/6 CTest Suites | 🟢 PASSED |
| **Sprint 08 (Hybrid Expansion)**| [sprint-08/PLAN.md](file:///etc/nixos/plan/troly/sprints/sprint-08/PLAN.md) | Autonomous Agent Tools & Desktop Pet Polish (`v01.08.00`) | 🟢 COMPLETED |
| **Sprint 08 Review** | [sprint-08/REVIEW.md](file:///etc/nixos/plan/troly/sprints/sprint-08/REVIEW.md) | Nghiệm thu 5/5 Tasks, 7/7 CTest Suites passed & Nix build | 🟢 PASSED |
| **Sprint 09 (Desktop Pet & Downloader)**| [sprint-09/PLAN.md](file:///etc/nixos/plan/troly/sprints/sprint-09/PLAN.md) | Standalone 3D Mascot Pet & GGUF Model Downloader (`v01.09.00`) | 🟢 COMPLETED |
| **Sprint 09 Review** | [sprint-09/REVIEW.md](file:///etc/nixos/plan/troly/sprints/sprint-09/REVIEW.md) | Nghiệm thu 5/5 Tasks, 8/8 CTest Suites passed & Nix build | 🟢 PASSED |
| **Daily Scrum** | [DAILY_SCRUM.md](file:///etc/nixos/plan/troly/scrum/DAILY_SCRUM.md) | Nhật ký hàng ngày của các AI Agent | 🟢 ACTIVE |

---

## 🔗 Liên Kết Hệ Thống
- 🏗️ **Tài liệu kiến trúc kỹ thuật:** [docs/troly/ARCHITECTURE.md](file:///etc/nixos/docs/troly/ARCHITECTURE.md)
- 🌿 **Quy chuẩn Git & DoD:** [docs/troly/GIT_WORKFLOW.md](file:///etc/nixos/docs/troly/GIT_WORKFLOW.md)
- ⚙️ **Quy chuẩn Agent Harness:** [docs/troly/ANTIGRAVITY_SETUP.md](file:///etc/nixos/docs/troly/ANTIGRAVITY_SETUP.md)
- 🌐 **Trung tâm tài liệu toàn hệ thống:** [docs/README.md](file:///etc/nixos/docs/README.md)

---

## 👥 Ma Trận Trách Nhiệm (RACI Matrix)

- **@PlanAgent:** Quản trị toàn bộ cấu trúc `plan/troly/`, cập nhật tiến độ Sprint, điều phối Review/Retro và Daily Scrum.
- **@RdAgent:** Đánh giá trade-off kỹ thuật, cập nhật giải pháp cho các ticket spike trong Sprint.
- **@DevOptAgent:** Nhận ticket, thực thi C++20 Clean Architecture, chạy kiểm thử và cập nhật Definition of Done (DoD).
- **@AnimAgent:** Chỉ đạo nghệ thuật nhân vật Mascot, chuẩn hóa animation 12 nguyên tắc Disney, FSM state và pipeline 3D.
