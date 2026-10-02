---
name: bamos-ecosystem-routing
description: Định tuyến subsystem theo tiền tố shorthand (?bamos, ?customizer, ?notes, ?installer, ?nvim) hoặc @subsystem trong prompt của User để tự động nạp đúng ngữ cảnh và phân quyền tác vụ.
---

# BamOS Ecosystem Subsystem Routing Skill

Quy chuẩn điều hướng và nạp ngữ cảnh cho AI Agent khi nhận yêu cầu có tiền tố chỉ định subsystem trong hệ sinh thái BamOS:

## 1. Bảng Tra Cứu Tiền Tố Subsystem (?prefix)

Khi User bắt đầu prompt bằng tiền tố `?<subsystem>:`, `@<subsystem>:`, hoặc `/<subsystem>:`, AI Agent tự động định tuyến vào đúng thư mục con:

| Tiền tố | Subsystem | Thư mục mục tiêu | Công nghệ chính |
| :--- | :--- | :--- | :--- |
| `?os` hoặc `?bamos` | BamOS Core System | [BamOS/](file:///home/quocnho/Projects/Bam/BamOS) | NixOS, Flakes, Home-Manager |
| `?customizer` | BamOS GUI Customizer | [BamApps/bam-customizer/](file:///home/quocnho/Projects/Bam/BamApps/bam-customizer) | Rust, GTK4, Libadwaita |
| `?notes` | Bam Notes App | [BamApps/bam-notes/](file:///home/quocnho/Projects/Bam/BamApps/bam-notes) | App ecosystem |
| `?installer` hoặc `?iso` | Live ISO & Calamares | [BamOS/profiles/installer/](file:///home/quocnho/Projects/Bam/BamOS/profiles/installer) | Calamares, Python, Nix ISO |
| `?nvim` | Neovim Config | [BamOS/home/dev/nvim/](file:///home/quocnho/Projects/Bam/BamOS/home/dev/nvim) | Lua, LSP, Treesitter |
| `?desktop` hoặc `?gnome` | GNOME & Theme | [BamOS/modules/gnome/](file:///home/quocnho/Projects/Bam/BamOS/modules/gnome) | Dconf, GDM, Extensions |
| `?audio` | PipeWire & Audio | [BamOS/modules/audio/](file:///home/quocnho/Projects/Bam/BamOS/modules/audio) | PipeWire, WirePlumber, Rnnoise |

## 2. Quy Trình Xử Lý Tự Động
1. **Cô Lập Ngữ Cảnh (Context Isolation)**:
   - Toàn bộ thao tác đọc (`view_file`), tìm kiếm (`grep_search`), sửa file và chạy lệnh chỉ tập trung trong thư mục subsystem đích.
2. **Kích Hoạt Tiêu Chuẩn Riêng**:
   - Tuân thủ file cấu hình hoặc `AGENTS.md` tương ứng của subsystem đó.
3. **Phản Hồi Trực Quan**:
   - Gắn nhãn xác nhận ở đầu câu trả lời: `[Target: BamOS/<subsystem>]` trước khi phân tích và thực thi.
