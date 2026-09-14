---
name: db-schema-validator
description: Hướng dẫn khởi tạo, di trú và kiểm thử cơ sở dữ liệu SQLite cho RAG (FTS5 + sqlite-vec), chế độ WAL và cấu trúc bảng trong dự án troly. Kích hoạt khi thao tác schema DB, truy vấn vector hoặc benchmark RAG.
---

# Mục Tiêu
Quản lý cơ sở dữ liệu SQLite cục bộ cho dự án `troly` đảm bảo tính toàn vẹn, tuân thủ lược đồ ERD & DDL chuẩn tại [docs/ARCHITECTURE.md](file:///etc/nixos/pkgs/troly/docs/ARCHITECTURE.md), hỗ trợ Hybrid Search (FTS5 + `sqlite-vec`), lưu vết ReAct Tool Calling và dữ liệu tự tiến hóa (Self-Evolving Hub).

> 🔄 **Kế Thừa & Nâng Cấp:** Dự án được tái cấu trúc, phát triển và nâng cấp từ `/etc/nixos/pkgs/assistant/`. Kế thừa toàn bộ cấu trúc dữ liệu lưu trữ từ hệ thống RAG cũ (tài liệu, phân đoạn, cấu hình settings, lịch sử phiên chat) sang mô hình SQLite WAL hiện đại.

# Quy Chuẩn Kết Nối SQLite Edge AI
1. **Chế độ WAL (Write-Ahead Logging) & Concurrency:**
   ```sql
   PRAGMA journal_mode = WAL;
   PRAGMA synchronous = NORMAL;
   PRAGMA foreign_keys = ON;
   PRAGMA busy_timeout = 5000;
   ```
2. **Nạp Thư Viện Vector (`sqlite-vec`):**
   ```cpp
   // Nạp tự động hoặc qua C API trước khi mở cơ sở dữ liệu
   sqlite3_auto_extension(reinterpret_cast<void(*)()>(sqlite3_vec_init));
   ```

# Các Bảng Cốt Lõi (Theo Lược Đồ DDL Chuẩn Trong `docs/ARCHITECTURE.md`)
- **Quản trị tài liệu RAG:** `collections`, `documents`, `doc_chunks`.
- **Bảng ảo tìm kiếm:**
  - Full-Text Search BM25: `chunks_fts USING fts5(content, content='doc_chunks', content_rowid='id')`.
  - Dense Vector: `vec_chunks USING vec0(chunk_id INTEGER PRIMARY KEY, embedding FLOAT[384])`.
- **Hội thoại & Lịch sử:** `chat_sessions`, `chat_messages`.
- **Kiểm toán Action ReAct Loop:** `action_logs` (lưu tool_name, arguments JSON, status, output).
- **Mô hình & Huấn luyện:** `models_registry`, `training_datasets` (mẫu vàng `quality_score >= 1.0`), `lora_checkpoints`.

# Thuật Toán Truy Vấn Hybrid Search
Kết hợp kết quả tìm kiếm từ khóa BM25 (`chunks_fts`) và khoảng cách Cosine (`vec_chunks`) qua thuật toán Reciprocal Rank Fusion (RRF) hoặc trọng số Alpha $\alpha \cdot \text{Dense} + (1-\alpha) \cdot \text{BM25}$. Tuyệt đối không chạy trên main thread, bao bọc bằng `std::jthread`.
