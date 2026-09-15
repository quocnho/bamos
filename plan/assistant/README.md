# 🗺️ Bản Đồ Lộ Trình & Kế Hoạch Dự Án Assistant (Project Plan Dashboard)

**Dự án:** `assistant` (BamOS AI Desktop Copilot & System Inspector)  
**Mã Package:** [`/etc/nixos/pkgs/assistant/`](file:///etc/nixos/pkgs/assistant/)  
**Phiên bản hiện hành:** `v0.3.0`  
**Phương pháp quản trị:** Agile Scrum Artifacts

---

## 🎯 Tổng Quan & Trọng Tâm Phát Triển

Package `assistant` là bản trợ lý ảo để bàn hiện hành của BamOS. Mục tiêu của chu kỳ phát triển hiện tại là:
1. **Kiến trúc bền vững (Hardening):** Giữ cho ứng dụng Go/WebKitGTK chạy mượt mà, trong suốt không viền đen trên mọi cấu hình XWayland / NVIDIA Hybrid GPU.
2. **Nâng cao chất lượng RAG:** Tối ưu hóa FTS5 + Vector Search cho kho tài liệu cục bộ, phản hồi nhanh và chính xác.
3. **Phục vụ bảo trì & song hành:** Duy trì tính năng ổn định cho người dùng hàng ngày đồng thời đóng vai trò tham chiếu chuẩn để đối chiếu khi hoàn thiện dự án `troly`.

---

## 🗂️ Cây Thư Mục Quản Trị Agile Scrum

```text
plan/assistant/
├── README.md                   # Trang chủ điều hướng & tổng quan tiến độ (File này)
├── backlog/
│   └── BACKLOG.md              # Product Backlog chi tiết, phân rã theo mã AST-xxx
├── sprints/
│   └── sprint-01/              # Sprint hiện hành
│       ├── PLAN.md             # Kế hoạch & Bảng phân công công việc Sprint 01
│       ├── REVIEW.md           # Đánh giá kết quả bàn giao Sprint 01
│       └── RETRO.md            # Đúc kết kinh nghiệm & Cải tiến quy trình
└── scrum/
    └── DAILY_SCRUM.md          # Nhật ký Standup hàng ngày của các AI Agent
```

---

## 📊 Trạng Thái Sprint Hiện Tại

| Sprint | Chủ Đề Trọng Tâm | Thời Gian | Trạng Thái | Phiên Bản |
| :--- | :--- | :--- | :--- | :--- |
| **Sprint 01** | Architecture Hardening, Documentation & RAG Optimization | 15/09/2026 - 29/09/2026 | 🟡 **IN_PROGRESS** | `v0.3.0` |

---

## 🔗 Liên Kết Nhanh
- 📖 **Cẩm nang kiến trúc hệ thống:** [docs/assistant/ARCHITECTURE.md](file:///etc/nixos/docs/assistant/ARCHITECTURE.md)
- 🌿 **Quy chuẩn Git commit (Why-What-Test):** [docs/assistant/GIT_WORKFLOW.md](file:///etc/nixos/docs/assistant/GIT_WORKFLOW.md)
- 🗺️ **Kế hoạch tổng thể BamOS:** [plan/README.md](file:///etc/nixos/plan/README.md)
