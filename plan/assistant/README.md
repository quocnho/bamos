# 🗺️ Bản Đồ Lộ Trình & Kế Hoạch Dự Án Assistant (Project Plan Dashboard)

**Dự án:** `assistant` (BamOS AI Desktop Copilot & System Companion)  
**Mã Package:** [`/etc/nixos/pkgs/assistant/`](file:///etc/nixos/pkgs/assistant/)  
**Phiên bản hiện hành:** `v0.3.1` (System Release Tag: `v01.11.00`)  
**Phương pháp quản trị:** Agile Scrum Artifacts

---

## 🎯 Tổng Quan & Trọng Tâm Phát Triển

Package `assistant` là bản trợ lý ảo để bàn hiện hành của BamOS. Mục tiêu của chu kỳ phát triển hiện tại là:
1. **Kiến trúc bền vững (Hardening):** Giữ cho ứng dụng Go/WebKitGTK chạy mượt mà, trong suốt không viền đen trên mọi cấu hình XWayland / NVIDIA Hybrid GPU; tự do mở rộng kích thước cửa sổ và neo chuẩn góc dưới bên phải màn hình.
2. **Module hóa giao diện sạch sẽ:** Phân tách toàn bộ các màn hình, popup và mascot thành các template HTML độc lập (`templates/`), loại bỏ hoàn toàn file HTML nguyên khối hơn 2.000 dòng.
3. **Mở rộng Web Widget & Auto-Discovery:** Hỗ trợ nhúng trợ lý vào website/app ngoài qua iframe và SSE stream, tự động quét card mạng IP/Hostname máy tính để tạo mã nhúng 1-click.
4. **Tự phục hồi AI Engine:** Cơ chế Auto-Recovery và dọn dẹp zombie process giúp `llama-server` luôn ổn định.

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
| **Sprint 01** | Window Fitting, Frontend Modularization, Web Widget & Network IP Scanner | 15/09/2026 - 29/09/2026 | 🟢 **COMPLETED (v0.3.1)** | `v0.3.1` (`v01.11.00`) |

---

## 🔗 Liên Kết Nhanh
- 📖 **Cẩm nang kiến trúc hệ thống:** [docs/assistant/ARCHITECTURE.md](file:///etc/nixos/docs/assistant/ARCHITECTURE.md)
- 🌿 **Quy chuẩn Git commit (Why-What-Test):** [docs/assistant/GIT_WORKFLOW.md](file:///etc/nixos/docs/assistant/GIT_WORKFLOW.md)
- 🗺️ **Kế hoạch tổng thể BamOS:** [plan/README.md](file:///etc/nixos/plan/README.md)
