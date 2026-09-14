# Tôn chỉ dự án BamOS (`/etc/nixos`) & Nguyên Tắc AI Agent

Hệ thống cấu hình NixOS toàn diện với Flake, Devenv, Home-Manager và các package con (`troly`, `assistant`, `bam`).

---

## 1. Quy Chuẩn Git Commit & Versioning Bắt Buộc (Why - What - Test)
Khi người dùng hoặc Agent thực hiện lệnh `git commit`, **bắt buộc tuân thủ cấu trúc Why - What - Test** theo chi tiết tại [.agents/rules/git-workflow.md](file:///.agents/rules/git-workflow.md) và [docs/troly/GIT_WORKFLOW.md](file:///docs/troly/GIT_WORKFLOW.md):

```text
<type>(<TICKET-ID-hoặc-SCOPE>): <tóm tắt ngắn gọn thay đổi> [vAA.BB.CC]

[WHY / BUSINESS CONTEXT]
- Lý do thực hiện thay đổi, bối cảnh nghiệp vụ, User Story hoặc nguyên nhân gốc (root cause).
- Vấn đề gặp phải nếu không áp dụng thay đổi này.

[WHAT / SCOPE OF CHANGE]
- Tóm tắt các thay đổi kỹ thuật chính theo mức tổng quan (high-level).
- Liệt kê các module, file hoặc cấu hình trọng tâm được chỉnh sửa/bổ sung.

[TEST / DEFINITION OF DONE]
- [x] Tiêu chí nghiệm thu (Acceptance Criteria) đã đạt.
- [x] Kiểm tra biên dịch / build nix / ctest (nếu áp dụng).
- [x] Kiểm thử giao diện hoặc kiểm thử cấu hình (`bam switch` / `bam dry` nếu áp dụng).

Closes: <TICKET-ID> (hoặc Refs: <TICKET-ID>)
```
> ⚠️ **Nghiêm cấm:** Không tự tiện commit 1 dòng sơ sài (`git commit -m "update"`) mà phải luôn phản ánh đầy đủ ngữ cảnh kỹ thuật và kiểm thử.

---

## 2. Phân Vai & Trách Nhiệm Agent
1. `@PlanAgent`: Chuyên trách quản lý cây thư mục `/plan/troly/` (`README.md`, `backlog/`, `sprints/`, `scrum/`) và `/docs/` bằng Markdown UI/UX chuẩn Agile Scrum.
2. `@RdAgent`: Phân tích kiến trúc, POC giải pháp kỹ thuật, đánh giá trade-off (VRAM, CPU, latency) trước khi viết code.
3. `@DevOptAgent`: Kỹ sư lập trình C++20, quản lý RAII, chạy test, commit chuẩn Git (Why-What-Test), đóng gói Nix package và thực hiện kiểm thử cập nhật hệ thống với lệnh `bam switch` (lệnh nixos switch của package `/etc/nixos/pkgs/bam`).
4. `@AnimAgent`: Chuyên gia cấp cao về Hoạt hình & Đồ họa Game 3D Realtime (12 nguyên tắc Disney, Squash & Stretch, Wayland 60fps, Qt Quick 3D).

---

## 3. Nguyên Tắc Tiết Kiệm AI Token & Clean Architecture
- **Phân rã hạt nhỏ nhất (Atomic Granularity):** Xây dựng hệ thống tập tin phân nhỏ nhất có thể thành các thư mục, tập tin phù hợp, chuyên nghiệp. Không tạo file fat/god class.
- **Dễ tìm kiếm & định vị:** Nội dung súc tích, module hóa cao để tiết kiệm tối đa token khi AI đọc/ghi mã.
- **Đường dẫn tương đối (Standalone Portability):** Mọi mã nguồn C++, QML, docs phải sử dụng đường dẫn tương đối để đảm bảo package con (`troly`, `assistant`) có thể chạy độc lập hoặc tách thành repo riêng mà không bị gãy đường dẫn.
