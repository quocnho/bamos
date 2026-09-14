# SPRINT 07: Self-Evolving Hub & 3D Mascot POC (Final Sprint)
**Thời gian:** 26/11/2026 - 10/12/2026 | **Trạng thái:** 🟢 COMPLETED | **Phiên bản:** `v01.07.00`

> 🎯 **Mục Tiêu Trọng Tâm Sprint 07:**
> Hoàn tất chặng đường phát triển của dự án Native Edge AI Desktop `troly` với 2 trụ cột đột phá:
> 1. Xây dựng **Self-Evolving Hub** (Trung tâm tự tiến hóa 100% Air-gapped):
>    - Trích xuất dữ liệu vàng (Dataset Golden Harvesting) từ các phiên hội thoại đạt điểm `quality_score >= 1.0` sang định dạng ChatML/JSONL.
>    - Xây dựng `SelfEvolvingService.hpp` quản lý quy trình 4 bước (Harvest -> Train LoRA script -> Merge Adapter -> Quantize GGUF).
>    - Tạo `SelfEvolvingViewModel` và modal quản lý đào tạo `SelfEvolvingModal.qml` hiển thị số lượng mẫu vàng, loss, epoch.
> 2. Thử nghiệm **3D Mascot Stylized Mesh POC**:
>    - Xây dựng thành phần `Mascot3DPOC.qml` dựa trên 12 nguyên tắc Disney, hỗ trợ xoay 3D trực quan, ánh xạ Toon shading và chuyển động đuôi linh hoạt.
> 3. Kiểm thử tự động qua CTest (`tests/test_self_evolving.cpp`) và kiểm tra đóng gói Nix derivation `v01.07.00`.

---

## 📋 Bảng Công Việc (Sprint Backlog)

| Task ID | Component | Phân loại | Người nhận | Ước lượng | Trạng thái | Ghi chú kỹ thuật |
|---|---|---|---|---|---|---|
| `TROLY-701` | Dataset Golden Harvesting | `feat` | @RdAgent, @DevOptAgent | 5 SP | 🟢 DONE | Trích xuất các phiên chat có `quality_score >= 1.0`, xuất ChatML |
| `TROLY-702` | Self-Evolving Service C++20 | `feat` | @DevOptAgent | 5 SP | 🟢 DONE | Quản lý pipeline LoRA offline an toàn qua `SelfEvolvingService.hpp` |
| `TROLY-703` | Self-Evolving UI & ViewModel | `feat` | @DevOptAgent | 3 SP | 🟢 DONE | ViewModel & `SelfEvolvingModal.qml` hiển thị dataset & trigger training |
| `TROLY-704` | Qt Quick 3D Stylized Mascot POC | `feat` | @AnimAgent, @DevOptAgent | 5 SP | 🟢 DONE | Thử nghiệm `Mascot3DPOC.qml` 3D viewport, Toon lighting, 60fps |
| `TROLY-705` | CTest Suite & Flake Packaging | `test` | @DevOptAgent | 3 SP | 🟢 DONE | `tests/test_self_evolving.cpp` đạt 100% CTest (6/6 suites) & Nix build |

---

## 👥 Ma Trận Phân Vai (RACI Sprint 07)

- **@PlanAgent:** Quản trị vòng đời Sprint 07, cập nhật hồ sơ backlog, Review & Retro và tổng kết toàn bộ dự án.
- **@RdAgent:** Thiết kế thuật toán bóc tách hội thoại mẫu vàng, cấu trúc ChatML và script gọi `llama-finetune`.
- **@DevOptAgent:** Lập trình C++20 Clean Architecture cho `SelfEvolvingService`, ViewModel, viết CTest và đóng gói Nix package.
- **@AnimAgent:** Thiết kế POC Mascot 3D chuyển động theo 12 nguyên tắc Disney (Squash & Stretch, Secondary Action, Toon Shading).

---

## 🔗 Liên Kết Hồ Sơ Agile Scrum
- **Chỉ mục kế hoạch tổng quan:** [plan/troly/README.md](file:///etc/nixos/plan/troly/README.md)
- **Master Product Backlog:** [plan/troly/backlog/BACKLOG.md](file:///etc/nixos/plan/troly/backlog/BACKLOG.md)
- **Sprint 06 Đã Nghiệm Thu:** [plan/troly/sprints/sprint-06/REVIEW.md](file:///etc/nixos/plan/troly/sprints/sprint-06/REVIEW.md)
- **Nhật ký Daily Standup:** [plan/troly/scrum/DAILY_SCRUM.md](file:///etc/nixos/plan/troly/scrum/DAILY_SCRUM.md)
