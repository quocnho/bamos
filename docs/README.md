# 📚 Trung Tâm Tài Liệu BamOS (System Documentation Hub)

Chào mừng bạn đến với trung tâm tài liệu kỹ thuật của cấu hình hệ thống **BamOS** (`/etc/nixos`).

Tài liệu được phân tầng rõ ràng giữa tài liệu cấp hệ thống (System level) và tài liệu chuyên sâu cho từng gói phần mềm / dịch vụ (Subpackages).

---

## 🗂️ 1. Danh Mục Tài Liệu Toàn Hệ Thống

| Tài liệu | Mô tả | Đối tượng |
| :--- | :--- | :--- |
| 🎋 [AI_GUIDE.md](file:///etc/nixos/docs/AI_GUIDE.md) | **Hướng dẫn Hệ thống BamAI & Tri thức RAG trên BamOS:**<br>• Cổng mạng (Port 9090 `llama-server`), nhúng vector store SQLite<br>• Tối ưu năng lượng GPU NVIDIA (RTD3 0W)<br>• Hướng dẫn nạp tri thức và giao tiếp trợ lý trên Desktop | Người dùng, Quản trị viên, AI Agent |
| 📖 [README.md (Root)](file:///etc/nixos/README.md) | **Tổng quan cấu hình NixOS:** Cấu trúc module Flake, Home-manager, Profiles máy | Kỹ sư hệ thống |

---

## 📦 2. Tài Liệu Các Package Con (Subpackages Documentation)

Mỗi package độc lập sở hữu một thư mục tài liệu chuyên sâu chuẩn Clean Architecture và Agile Scrum:

### 🐶 Dự Án Troly (`/docs/troly/`)
*Native Edge AI Desktop Companion (C++20, Qt6/QML, SQLite WAL + `sqlite-vec`, Air-gapped SLM).*

- 🗂️ **Chỉ mục tổng quan Troly:** [docs/troly/README.md](file:///etc/nixos/docs/troly/README.md)
- 🏗️ **Kiến trúc hệ thống chi tiết:** [docs/troly/ARCHITECTURE.md](file:///etc/nixos/docs/troly/ARCHITECTURE.md) *(Clean Arch 4 tầng, ERD/DDL SQLite, DFD ReAct Loop, Mascot FSM Disney 60fps)*
- 🌿 **Quy chuẩn Git & Versioning:** [docs/troly/GIT_WORKFLOW.md](file:///etc/nixos/docs/troly/GIT_WORKFLOW.md) *(Chiến lược vAA.BB.CC, Branching Ticket, Commit Why-What-Test, DoD)*
- ⚙️ **Thiết lập Antigravity IDE:** [docs/troly/ANTIGRAVITY_SETUP.md](file:///etc/nixos/docs/troly/ANTIGRAVITY_SETUP.md) *(Rules vs Skills, Context Injection, Atomic Granularity)*

---

## 🔗 Liên Kết Hệ Thống Kế Hoạch & Lộ Trình (`/plan/`)
- 🗺️ **Bản đồ kế hoạch hệ thống tổng thể:** [plan/README.md](file:///etc/nixos/plan/README.md)
- 🎯 **Kế hoạch Agile Scrum Troly:** [plan/troly/README.md](file:///etc/nixos/plan/troly/README.md)
