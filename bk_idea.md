# 📚 Kho Lưu Trữ Ý Tưởng Đã Chuẩn Hóa (Archived Ideas)

Tài liệu này lưu trữ các ý tưởng đã được tinh chỉnh, đối chiếu kiến trúc và người dùng xác nhận thông qua quy trình Vibe Coding với AI Agent.

---

## Danh Sách Ý Tưởng Đã Duyệt

### [IDEA-BAM-20261002-01] Ứng dụng Bam Notes (`bam-notes`) - Workspace & Block Editor 99% Notion trên BamOS
- **Ngày duyệt**: 2026-10-02
- **Subsystem**: `BamApps/bam-notes`, `BamOS/modules/features/`, `BamOS/pkgs/`
- **Mục tiêu**: Xây dựng ứng dụng ghi chú, quản lý tri thức dạng khối (Block-based Workspace) đạt độ hoàn thiện và trải nghiệm 99% Notion, vận hành Local-first, bảo mật, sao lưu và đồng bộ hai chiều với Google Drive.
- **Kiến trúc cốt lõi**:
  - Frontend: Tauri v2 + TypeScript + BlockSuite / TipTap engine + Tailwind/Adwaita CSS theme.
  - Backend: Rust Core (Local Markdown/SQLite Storage, Full-text Search, Google Drive REST API OAuth2 sync daemon).
  - Đóng gói BamOS: Nix package derivation, option `bam.features.office.bam-notes.enable`, tích hợp catalog của `bam-customizer`.
- **Trạng thái**: Đã phê duyệt ➔ Đang tiến hành tạo Roadmap & Scaffolding.

