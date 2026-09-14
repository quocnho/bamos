# Quy Chuẩn Git Commit & Versioning Bắt Buộc (Why - What - Test)

Quy chuẩn này áp dụng **bắt buộc cho tất cả các thao tác `git commit`** trong toàn bộ workspace (`/etc/nixos`). AI Agent tuyệt đối không tự ý viết commit ngắn 1 dòng khi thực hiện lệnh commit, trừ khi người dùng có chỉ thị rõ ràng khác.

---

## 1. Định Dạng Commit Message Chuẩn

Mỗi commit phải tuân thủ cấu trúc 3 phần (**Why - What - Test**) dựa trên [docs/troly/GIT_WORKFLOW.md](file:///etc/nixos/docs/troly/GIT_WORKFLOW.md):

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

---

## 2. Quy Tắc Chi Tiết Cho Từng Trường Hợp

### A. Đối với công việc thuộc Task / Ticket (vd: `troly`, `assistant`, `bam`):
- **`<type>`**: `feat`, `fix`, `refactor`, `chore`, `docs`, `test`, `spike`, `hotfix`.
- **`<TICKET-ID>`**: Mã ticket từ Sprint Backlog (ví dụ: `TROLY-101`, `BAM-02`). Nếu không có ticket ID riêng, ghi scope của module (ví dụ: `infra`, `flake`, `desktop`).
- **`[vAA.BB.CC]`**: Đánh số phiên bản 3 cấp (`Major.Sprint.Task`):
  - `AA`: Major version (kiến trúc lớn, breaking changes).
  - `BB`: Sprint version (tăng khi kết thúc sprint merge vào `main`).
  - `CC`: Task version (tăng sau mỗi task merge vào `develop`).

### B. Đối với commit hạ tầng / cấu hình hệ thống NixOS chung:
- Nếu là thay đổi cấu hình hệ thống NixOS hoặc dotfiles không thuộc sprint ticket:
  - Header: `<type>(<subsystem>): <tóm tắt ngắn gọn>`
  - Phần `[TEST / DEFINITION OF DONE]` bắt buộc ghi rõ trạng thái kiểm thử `bam dry` hoặc `bam switch`.

---

## 3. Quy Trình Thực Hiện Của AI Agent

Khi người dùng yêu cầu `git commit` (hoặc `git add, commit, push`):
1. **Kiểm tra trạng thái thay đổi:** Chạy `git status` và `git diff --stat` để nắm rõ danh sách file thay đổi.
2. **Xác định bối cảnh thay đổi:**
   - Thuộc ticket nào trong Sprint Backlog (nếu có)?
   - Mục đích thay đổi (Why), nội dung kỹ thuật (What) và đã kiểm thử gì (Test).
3. **Soạn commit message đầy đủ 3 block:**
   - Tuyệt đối không dùng `git commit -m "short line"` sơ sài.
   - Sử dụng commit message chuẩn nhiều dòng có cấu trúc Why - What - Test.
