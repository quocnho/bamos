---
name: bamos-agile-workflow
description: Quy trình phối hợp Agile Scrum cho Solo Coder và AI Agent (Vibe Coding) trên hệ sinh thái BamOS & BamApps. Quản lý ý tưởng (idea.md -> bk_idea.md), nhịp Sprint, DoD, và release milestone.
---

# BamOS & BamApps Agile & Vibe Coding Workflow Skill

Kỹ năng này hướng dẫn AI Agent và Solo Coder vận hành nhịp nhàng theo phương pháp Agile Scrum trong việc phát triển hệ điều hành BamOS và các ứng dụng BamApps (bam-customizer, bam-notes, ...).

## 1. Phân Định Vai Trò
- **Solo Coder**: Product Owner, Lead System Architect & Maintainer. Quyết định định hướng kiến trúc OS/App, thẩm định cấu hình Nix/Rust/GTK4, nghiệm thu DoD.
- **AI Agent**: Scrum Master & Co-pilot. Kiểm soát tiêu chuẩn DoD/DoR, cập nhật tài liệu sprint, sinh code tuân thủ micro-module (<80-100 dòng) và bảo toàn tính toàn vẹn của hệ thống.

## 2. Quy Trình Tiếp Nhận & Tinh Chỉnh Ý Tưởng (idea.md ➔ bk_idea.md)
Khi người dùng đưa ra yêu cầu mới (qua đoạn chat hoặc viết trong `idea.md`):
1. **Đọc & Phân Tích (Read & Understand)**: Đọc kỹ yêu cầu và đối chiếu với cấu trúc NixOS/Rust hiện hành.
2. **Tinh Chỉnh & Diễn Đạt Lại Chuyên Nghiệp (Refine & Reframe)**:
   - Viết lại yêu cầu theo cấu trúc rõ ràng: Bối cảnh (Context), Mục tiêu hệ thống (Goal), Subsystem/Package tác động (Affected modules/apps), Giải pháp kỹ thuật đề xuất (Technical Architecture).
   - Định nghĩa Acceptance Criteria (Tiêu chí nghiệm thu) cụ thể.
3. **Xác Thực Lại Với Người Dùng (Verification)**:
   - Trình bày bản Refine/Reframe và hỏi xác nhận từ người dùng trước khi tiến hành chỉnh sửa mã nguồn phức tạp.
4. **Biến Thành Ý Tưởng & Đồng Bộ**:
   - Gán mã định danh chuẩn hóa (ví dụ: `[IDEA-BAM-YYYYMMDD-XX]`).
   - Lưu trữ vào `bk_idea.md` và dọn trống mục nháp trong `idea.md`.
5. **Tiến Hành Triển Khai**: Sau khi xác nhận, bắt đầu viết module Nix hoặc code ứng dụng.

## 3. Quản Trị Nhịp Sprint & DoD
- **Độ dài Sprint**: 1-2 tuần tương ứng một mốc phiên bản phát hành `CC` (`vAA.BB.CC`).
- **Definition of Done (DoD) cho BamOS & BamApps**:
  1. Mã nguồn Nix: `nix flake check` hoặc `nix-instantiate` không có lỗi cú pháp.
  2. Mã nguồn Rust/Apps: `cargo clippy -- -D warnings` và `cargo fmt --check` vượt qua hoàn hảo.
  3. Kích thước file: Mỗi file micro-module duy trì < 80 dòng (Nix) và < 100 dòng (Rust/UI).
  4. Trạng thái Git sạch sẽ, không commit file rác (`result`, `.direnv`, `target/`).
