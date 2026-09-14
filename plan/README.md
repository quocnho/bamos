# 🗺️ Trung Tâm Quản Lý Lộ Trình & Kế Hoạch Dự Án (Project Portfolio & Roadmaps)

Chào mừng bạn đến với trung tâm quản trị kế hoạch và tiến độ các gói phần mềm thuộc hệ điều hành **BamOS** (`/etc/nixos`).

Mọi dự án và package con quan trọng đều được tổ chức kế hoạch theo chuẩn **Agile Scrum Artifacts** để đảm bảo tính minh bạch, theo dõi tiến độ thời gian thực và tạo điều kiện cho các AI Agent phối hợp tự động.

---

## 📦 Danh Mục Dự Án Đang Triển Khai

| Gói Phần Mềm | Thư Mục Kế Hoạch | Trọng Tâm Phát Triển | Trạng Thái Sprint Hiện Tại |
| :--- | :--- | :--- | :--- |
| **🐶 `troly`** | [plan/troly/README.md](file:///etc/nixos/plan/troly/README.md) | Trợ lý ảo Native Edge AI Desktop (C++20, Qt6, SQLite Vector RAG, Disney Mascot) | 🟡 **Sprint 01: Core Architecture & Setup** |
| **🎋 `assistant`** | `/etc/nixos/pkgs/assistant/` | Bản tiền nhiệm (Go + WebKitGTK). Đang được di chuyển và kế thừa tính năng sang `troly`. | 🟢 Bảo trì / Chuyển giao |
| **⚡ `bam`** | `/etc/nixos/pkgs/bam/` | Bộ công cụ CLI quản trị hệ thống (`bam switch`, `bam update`, `bam backup`). | 🟢 Hoạt động ổn định |

---

## 🎯 Cấu Trúc Hồ Sơ Agile Scrum Chuẩn Cho Từng Package (Ví dụ `/plan/troly/`)

```text
plan/<package_name>/
├── README.md                   # Chỉ mục điều hướng & bản đồ tổng quan của package
├── backlog/
│   └── BACKLOG.md              # Product Backlog chi tiết, phân rã chức năng (F1, F2,...)
├── sprints/
│   ├── sprint-01/              # Sprint cụ thể
│   │   ├── PLAN.md             # Bảng công việc Sprint & Trọng tâm cam kết
│   │   ├── REVIEW.md           # Đánh giá kết quả bàn giao Sprint (Demo & DoD)
│   │   └── RETRO.md            # Cải tiến quy trình & Action items
│   └── sprint-02/              # Các Sprint tiếp theo...
└── scrum/
    └── DAILY_SCRUM.md          # Nhật ký làm việc hàng ngày của các AI Agent & Developer
```

---

## 👥 Hệ Sinh Thái AI Agent Điều Phối
- **@PlanAgent:** Quản trị lộ trình, cập nhật tiến độ Sprint, điều phối Daily Scrum và chuẩn hóa tài liệu.
- **@RdAgent:** Nghiên cứu kỹ thuật, POC giải pháp, đánh giá trade-off trước khi thực thi.
- **@DevOptAgent:** Lập trình C++20, quản lý RAII, test, build derivation và kiểm thử cập nhật hệ thống với `bam switch`.
- **@AnimAgent:** Chỉ đạo mỹ thuật mascot 12 nguyên tắc Disney, FSM và đồ họa Scene Graph 60fps.
