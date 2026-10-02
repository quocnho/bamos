---
name: bamos-modular-architecture
description: Enforces file length (< 80 lines for Nix, < 100 lines for Rust/C++), Atomic Micro-Modules, token conservation strategy, and FOSS licensing across BamOS and BamApps.
---

# BamOS Modular Architecture & Token Conservation Skill

Quy chuẩn kiến trúc vi mô và kỹ thuật tiết kiệm token AI tối đa khi làm việc trên BamOS & BamApps:

## 1. Triết Lý Atomic Micro-Modules ("Cây Tre Trăm Đốt")
- **Ngưỡng giới hạn dòng chặt chẽ**:
  - File cấu hình NixOS / Home-Manager: **TỐI ĐA < 80 dòng/file**. Khi đạt ~70 dòng, chủ động tách thành các module con và dùng `default.nix` làm aggregator.
  - File mã nguồn Rust, C++, Python, Shell: **TỐI ĐA < 100 dòng/file**. Tách nhỏ components, structs, helpers.
- **Tính độc lập & Shim Pattern**:
  - Mọi thư mục module lớn (vd: `modules/gnome/`, `modules/audio/`) đều có `default.nix` nội bộ và một file shim ngang hàng (vd: `modules/gnome.nix` trỏ vào `modules/gnome/default.nix`) để giữ tương thích ngược 100%.

## 2. Chiến Lược Tiết Kiệm Token AI Tối Đa (Token Conservation)
- **Đọc chính xác (Targeted Reading)**:
  - Tra cứu cấu trúc file trong `AGENTS.md` trước khi đọc.
  - Sử dụng `grep_search` để định vị ký hiệu thay vì đọc lướt hàng loạt file.
  - Luôn chỉ định `StartLine` và `EndLine` khi gọi `view_file`.
  - **Không bao giờ đọc**: `assets/images/`, `assets/fonts/`, `assets/icons/`, `flake.lock`, `Cargo.lock`, file nhị phân, hoặc `target/`.
- **Chỉnh sửa vi phẫu (Surgical Edits)**:
  - Dùng `replace_file_content` hoặc `multi_replace_file_content` với chunk tối giản.
  - Tránh tuyệt đối việc ghi đè lại cả file chỉ để sửa vài dòng.

## 3. Tiêu Chuẩn 100% FOSS & Không Bản Quyền Thương Mại
- Toàn bộ fonts, tiện ích, icon, themes nhúng vào hệ điều hành BamOS hoặc ứng dụng BamApps đều phải có giấy phép tự do: **GPL-3.0, MIT, Apache 2.0, BSD, SIL OFL**.
- Tuyệt đối không tích hợp các thành phần đòi hỏi license thương mại hoặc trả phí.
