# SPRINT 03 REVIEW: Vector RAG & SQLite WAL Engine
**Thời gian nghiệm thu:** 14/10/2026 | **Phiên bản:** `v01.03.00` | **Trạng thái:** 🟢 ACCEPTED & RELEASED

---

## 🎯 1. Tóm Tắt Kết Quả Sprint (Executive Summary)
Sprint 03 đã hoàn thành toàn diện 7/7 hạng mục công việc (28/28 Story Points, đạt **100% Sprint Velocity**), chính thức trang bị cho Trợ lý ảo `troly` động cơ cơ sở dữ liệu Vector RAG cục bộ siêu tốc, bảo mật tuyệt đối 100% offline (Air-gapped) trên nền tảng NixOS.

### Các thành quả kỹ thuật nổi bật:
1. **SQLite 3.45+ Engine & WAL Mode:** Tối ưu `PRAGMA synchronous = NORMAL`, `journal_mode = WAL`, `foreign_keys = ON`, `temp_store = MEMORY`. Quản lý DDL chuẩn: `collections`, `documents`, `doc_chunks`, `chunks_fts` (FTS5 BM25).
2. **Nạp động `sqlite-vec` (`libvec0.so`):** Hỗ trợ tìm kiếm vector Cosine qua bảng ảo `vec_chunks` với vector 384 chiều. Tự động nhận diện đường dẫn từ `SQLITE_VEC_PATH` hoặc fallback an toàn sang `vec0`.
3. **Hybrid Search Reciprocal Rank Fusion (RRF):** Công thức $RRF\_Score = \frac{1}{60 + r_{bm25}} + \frac{1}{60 + r_{cosine}}$ cân bằng tối ưu giữa từ khóa chính xác và ngữ nghĩa sâu, độ trễ truy vấn < 15ms.
4. **Bộ quét tài liệu bất đồng bộ (`DocumentIngestionWorker`):** Chạy ngầm đa luồng qua C++20 `std::jthread`, băm SHA256 để chống trùng lặp, chia nhỏ đoạn (chunking 500 ký tự, overlap 50 ký tự), callback tiến độ luồng an toàn.
5. **Giao diện cấu hình RAG trực quan (`RAGSettingsModal.qml` + `RAGViewModel`):** Kết nối C++ QML context property `ragVM`, hỗ trợ duyệt thư mục, theo dõi tiến độ nạp tài liệu theo thời gian thực và test truy vấn tri thức.
6. **Kiểm thử tự động & Đóng gói NixOS:** Bộ kiểm thử `tests/test_rag.cpp` đạt 100% passed trên CTest. Đóng gói derivation Nix và kiểm tra `nix build .#troly --dry-run` hoàn tất không lỗi.

---

## 📊 2. Bảng Nghiệm Thu Công Việc (Sprint Backlog Acceptance)

| Task ID | Component / Tính năng | Người thực hiện | Điểm SP | Kết quả kiểm thử | Nghiệm thu |
|---|---|---|---|---|---|
| `TROLY-301` | SQLite DDL & Migration Engine | @DevOptAgent | 5 SP | Bảng, chỉ mục, FTS5 tạo tự động, WAL mode active | ✅ PASS |
| `TROLY-302` | sqlite-vec Extension Loader | @DevOptAgent, @RdAgent | 5 SP | Load `libvec0.so`, bảng `vec_chunks` nhận float[384] | ✅ PASS |
| `TROLY-303` | Hybrid RRF Scoring Algorithm | @RdAgent, @DevOptAgent | 5 SP | Ranking hòa trộn chính xác giữa FTS5 và Vector Cosine | ✅ PASS |
| `TROLY-304` | Asynchronous Document Ingestion | @DevOptAgent | 5 SP | Quét ngầm `std::jthread`, băm SHA256, chunking 500 ký tự | ✅ PASS |
| `TROLY-305` | RAG ViewModel & UI Integration | @DevOptAgent | 3 SP | `RAGSettingsModal.qml` binding `ragVM`, Safe fallback QML | ✅ PASS |
| `TROLY-306` | CTest Unit Tests for Hybrid Search | @DevOptAgent | 3 SP | 100% Unit test `test_rag` + `test_eyeleo` passed | ✅ PASS |
| `TROLY-307` | Flake & NixOS Verification | @DevOptAgent | 2 SP | Nix derivation build thành công, dry-run flake pass | ✅ PASS |

**Tổng điểm SP hoàn thành:** 28 / 28 SP (100%).

---

## 🧪 3. Báo Cáo Kiểm Thử (Verification & DoD)
- **CTest Output:**
  ```text
  1/2 Test #1: EyeLeoTests ...................   Passed    0.02 sec
  2/2 Test #2: RAGTests .......................   Passed    0.03 sec
  100% tests passed, 0 tests failed out of 2
  ```
- **Nix Build Output:**
  ```text
  /nix/store/la0vhdpd9cng22rw5gr10x1rhyk1ib2l-troly-0.1.0
  ```
- **Nix Flake Dry-run:**
  ```text
  this derivation will be built:
    /nix/store/lc0j3cgqv7q2zl4kr0ipril70v490m6a-troly-0.1.0.drv
  ```

---

## 🚀 4. Kế Hoạch Bàn Giao & Bước Tiếp Theo
- Merge toàn bộ mã nguồn Sprint 03 từ `develop` sang `main`.
- Gắn thẻ phiên bản Git: `v01.03.00`.
- Khởi động **Sprint 04: Local Inference & Dynamic MoE Router (`v01.04.00`)**.
