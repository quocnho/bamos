# SPRINT 03: Vector RAG & SQLite WAL Engine
**Thời gian:** 30/09/2026 - 14/10/2026 | **Trạng thái:** 🟢 COMPLETED | **Phiên bản:** `v01.03.00`

> 🎯 **Mục Tiêu Trọng Tâm Sprint 03:**
> Hiện thực hóa động cơ tri thức cục bộ **Hybrid RAG Engine (100% Air-gapped)**:
> 1. Triển khai cấu trúc cơ sở dữ liệu SQLite 3.45+ chế độ WAL, tối ưu `PRAGMA synchronous = NORMAL`.
> 2. Nạp động thư viện vector extension `sqlite-vec` (`libvec0.so`) trong môi trường NixOS.
> 3. Thuật toán tìm kiếm lai **Hybrid Search Scoring**: kết hợp từ khóa BM25 (`chunks_fts`) và khoảng cách vector Cosine (`vec_chunks`) qua công thức Reciprocal Rank Fusion (RRF).
> 4. Bộ quét tệp chạy ngầm đa luồng `std::jthread` (Text Extraction, SHA256 Hashing, Recursive Directory Walker).
> 5. Kết nối QML ViewModel với cửa sổ thiết lập [RAGSettingsModal.qml](file:///etc/nixos/pkgs/troly/src/presentation/ui/RAGSettingsModal.qml).

---

## 📋 Bảng Công Việc (Sprint Backlog)

| Task ID | Component | Phân loại | Người nhận | Ước lượng | Trạng thái | Ghi chú kỹ thuật |
|---|---|---|---|---|---|---|
| `TROLY-301` | SQLite DDL & Migration Engine | `feat` | @DevOptAgent | 5 SP | 🟢 DONE | Hoàn thành schema DDL chuẩn: `collections`, `documents`, `doc_chunks`, `chunks_fts` |
| `TROLY-302` | sqlite-vec Extension Loader | `feat` | @DevOptAgent, @RdAgent | 5 SP | 🟢 DONE | Nạp `libvec0.so`, tạo virtual table `vec_chunks (chunk_id INT, embedding FLOAT[384])` |
| `TROLY-303` | Hybrid RRF Scoring Algorithm | `feat` | @RdAgent, @DevOptAgent | 5 SP | 🟢 DONE | Thuật toán Reciprocal Rank Fusion ($k=60$) kết hợp điểm FTS5 BM25 và khoảng cách Cosine |
| `TROLY-304` | Asynchronous Document Ingestion | `feat` | @DevOptAgent | 5 SP | 🟢 DONE | Quét thư mục nền `std::jthread`, băm SHA256 chống trùng lặp, chia chunk 500 ký tự |
| `TROLY-305` | RAG ViewModel & UI Integration | `feat` | @DevOptAgent | 3 SP | 🟢 DONE | Kết nối `RAGSettingsModal.qml` hiển thị tiến độ quét, danh sách collections và test truy vấn |
| `TROLY-306` | CTest Unit Tests for Hybrid Search | `test` | @DevOptAgent | 3 SP | 🟢 DONE | `tests/test_rag.cpp` vượt qua 100% CTest tự động (khởi tạo, embedding mock, RRF query) |
| `TROLY-307` | Flake & NixOS Verification | `chore` | @DevOptAgent | 2 SP | 🟢 DONE | Đóng gói derivation và kiểm tra dry-run flake toplevel NixOS thành công 100% |

---

## 👥 Ma Trận Phân Vai (RACI Sprint 03)

- **@PlanAgent:** Theo dõi tiến độ Sprint 03, điều phối Daily Scrum, cập nhật Review/Retro khi hoàn thành.
- **@RdAgent:** Đánh giá công thức RRF vs Alpha Weighted Scoring, benchmark độ trễ truy vấn vector dưới 50ms.
- **@DevOptAgent:** Lập trình C++20 Clean Architecture, quản lý kết nối SQLite RAII, viết CTest và đóng gói derivation.
- **@AnimAgent:** Thiết kế hoạt ảnh cún cưng lúc đang tìm kiếm tri thức (cún đánh hơi, tìm sách).

---

## 🔗 Liên Kết Hồ Sơ Agile Scrum
- **Chỉ mục kế hoạch tổng quan:** [plan/troly/README.md](file:///etc/nixos/plan/troly/README.md)
- **Master Product Backlog:** [plan/troly/backlog/BACKLOG.md](file:///etc/nixos/plan/troly/backlog/BACKLOG.md)
- **Sprint 02 Đã Nghiệm Thu:** [plan/troly/sprints/sprint-02/REVIEW.md](file:///etc/nixos/plan/troly/sprints/sprint-02/REVIEW.md)
- **Nhật ký Daily Standup:** [plan/troly/scrum/DAILY_SCRUM.md](file:///etc/nixos/plan/troly/scrum/DAILY_SCRUM.md)
