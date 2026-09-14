# SPRINT 04: Local Inference & Dynamic MoE Router
**Thời gian:** 14/10/2026 - 28/10/2026 | **Trạng thái:** 🟢 COMPLETED | **Phiên bản:** `v01.04.00`

> 🎯 **Mục Tiêu Trọng Tâm Sprint 04:**
> Xây dựng hệ thống suy luận cục bộ (Local Inference Engine) và bộ định tuyến chuyên biệt (Dynamic MoE Router) tối ưu trên NixOS:
> 1. Triển khai **HTTP/SSE Client** C++20 kết nối `llama-server` (local port `8080`/`9090`), hỗ trợ streaming tokens thời gian thực và ngắt tác vụ tức thì (`std::stop_token`).
> 2. Xây dựng **Intent Classifier (<30ms)** phân loại ý định người dùng (Code / Text / System / Vision).
> 3. Hiện thực **Dynamic MoE Router**: điều phối nạp động slot mô hình chuyên biệt, giám sát ngân sách VRAM (< 6GB).
> 4. Tích hợp động cơ **Hybrid RAG** (từ Sprint 03) trực tiếp vào ngữ cảnh hội thoại (Context Augmentation).
> 5. Nối kết ViewModel với [LLMSettingsModal.qml](file:///etc/nixos/pkgs/troly/src/presentation/ui/LLMSettingsModal.qml).
> 6. Kiểm thử tự động qua CTest (`tests/test_inference.cpp`) và kiểm tra đóng gói NixOS.

---

## 📋 Bảng Công Việc (Sprint Backlog)

| Task ID | Component | Phân loại | Người nhận | Ước lượng | Trạng thái | Ghi chú kỹ thuật |
|---|---|---|---|---|---|---|
| `TROLY-401` | Llama HTTP/SSE Streaming Client | `feat` | @DevOptAgent | 5 SP | 🟢 DONE | Kết nối `llama-server` SSE (`/v1/chat/completions`), stream token, abort `std::stop_token` |
| `TROLY-402` | Ultra-fast Intent Classifier | `feat` | @RdAgent, @DevOptAgent | 5 SP | 🟢 DONE | Phân loại ý định (<30ms): `CODE`, `GENERAL_TEXT`, `SYSTEM_COMMAND`, `KNOWLEDGE_QUERY` |
| `TROLY-403` | Dynamic MoE Model Router | `feat` | @RdAgent, @DevOptAgent | 5 SP | 🟢 DONE | Cơ chế hot-swap slot model chuyên biệt, giám sát VRAM Budget Supervisor (< 6GB) |
| `TROLY-404` | RAG Context Augmenter | `feat` | @DevOptAgent | 3 SP | 🟢 DONE | Ghép tri thức liên quan từ `SqliteRAGRepository` vào Prompt Template |
| `TROLY-405` | LLM ViewModel & Settings UI | `feat` | @DevOptAgent | 3 SP | 🟢 DONE | Kết nối `LLMSettingsModal.qml` điều chỉnh URL, Temperature, Max Tokens, Active Model |
| `TROLY-406` | CTest Unit Tests for Inference | `test` | @DevOptAgent | 3 SP | 🟢 DONE | `tests/test_inference.cpp` đạt 100% CTest (Heuristic Classifier, MoE Router, Mock Stream) |
| `TROLY-407` | Flake & NixOS Verification | `chore` | @DevOptAgent | 2 SP | 🟢 DONE | Đóng gói derivation thành công và kiểm tra `nix build .#troly --dry-run` hoàn tất |

---

## 👥 Ma Trận Phân Vai (RACI Sprint 04)

- **@PlanAgent:** Theo dõi tiến độ Sprint 04, đồng bộ hồ sơ Scrum, đảm bảo quy chuẩn Why-What-Test.
- **@RdAgent:** Thiết kế luật heuristic và vector matching cho Intent Classifier (<30ms), benchmark độ trễ VRAM hot-swap.
- **@DevOptAgent:** Lập trình C++20 Clean Architecture, quản lý bất đồng bộ `std::jthread`, viết CTest và đóng gói Nix.
- **@AnimAgent:** Thiết kế hoạt ảnh cún suy nghĩ / đọc sách khi đang stream tokens (`thinking` state).

---

## 🔗 Liên Kết Hồ Sơ Agile Scrum
- **Chỉ mục kế hoạch tổng quan:** [plan/troly/README.md](file:///etc/nixos/plan/troly/README.md)
- **Master Product Backlog:** [plan/troly/backlog/BACKLOG.md](file:///etc/nixos/plan/troly/backlog/BACKLOG.md)
- **Sprint 03 Đã Nghiệm Thu:** [plan/troly/sprints/sprint-03/REVIEW.md](file:///etc/nixos/plan/troly/sprints/sprint-03/REVIEW.md)
- **Nhật ký Daily Standup:** [plan/troly/scrum/DAILY_SCRUM.md](file:///etc/nixos/plan/troly/scrum/DAILY_SCRUM.md)
