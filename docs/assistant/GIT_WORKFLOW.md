# 🌿 Quy Chuẩn Git Workflow & Quản Trị Phiên Bản Dự Án Assistant

Quy chuẩn này là **bắt buộc** áp dụng cho mọi hoạt động commit và quản lý phiên bản trong dự án **`assistant`** (`/etc/nixos/pkgs/assistant/`).

---

## 1. Chiến Lược Đánh Số Phiên Bản (Semantic Versioning 3 Cấp)

Dự án `assistant` tuân thủ định dạng 3 cấp: **`vAA.BB.CC`**
- **`AA` (Major Version):** Tăng khi có thay đổi bước ngoặt về kiến trúc hoặc breaking change (Ví dụ: `v0` hiện tại chuyển đổi sang `v1` khi hoàn tất refactor module độc lập).
- **`BB` (Sprint Version):** Tăng khi hoàn thành một chu kỳ Sprint và merge mã nguồn ổn định vào nhánh chính (Hiện tại: `v0.3.0` từ `default.nix`).
- **`CC` (Task / Hotfix Version):** Tăng sau khi hoàn thành từng Task / Ticket con (`AST-xxx`) trong Sprint.

---

## 2. Quy Tắc Định Danh Ticket ID & Nhánh (Branching)

- **Tiền tố Ticket chuẩn:** `AST-xxx` (Ví dụ: `AST-101`, `AST-102`).
- **Đặt tên nhánh:**
  - Nhánh tính năng mới: `feat/AST-<id>-<mo-ta-ngan>`
  - Nhánh sửa lỗi: `fix/AST-<id>-<mo-ta-ngan>`
  - Nhánh tài liệu / cấu hình: `docs/AST-<id>-<mo-ta-ngan>` hoặc `chore/AST-<id>-<mo-ta-ngan>`

---

## 3. Mẫu Commit Message Chuẩn (Why - What - Test)

Mọi commit của nhà phát triển hoặc AI Agent (`@AssistantDevAgent`, `@AssistantPlanAgent`) bắt buộc phải tuân theo cấu trúc 3 phần:

```text
<type>(AST-<ID>): <tóm tắt ngắn gọn thay đổi> [vAA.BB.CC]

[WHY / BUSINESS CONTEXT]
- Lý do thực hiện thay đổi, bối cảnh bài toán, User Story hoặc nguyên nhân gốc (root cause).
- Vấn đề gặp phải nếu không áp dụng thay đổi này.

[WHAT / SCOPE OF CHANGE]
- Tóm tắt các thay đổi kỹ thuật chính (high-level).
- Liệt kê các tập tin Go, HTML/CSS frontend hoặc cấu hình Nix được chỉnh sửa/bổ sung.

[TEST / DEFINITION OF DONE]
- [x] Đạt tiêu chí nghiệm thu (Acceptance Criteria).
- [x] Kiểm tra định dạng mã nguồn: go fmt ./... && go vet ./...
- [x] Kiểm tra biên dịch & unit test: go test ./...
- [x] Kiểm thử đóng gói Nix hoặc kiểm thử cập nhật hệ thống (bam switch / bam dry nếu áp dụng).

Closes: AST-<ID> (hoặc Refs: AST-<ID>)
```

---

## 4. Tiêu Chuẩn Nghiệm Thu Kỹ Thuật (Definition of Done - DoD)

Một ticket thuộc `assistant` chỉ được đánh dấu là 🟢 **DONE** khi đáp ứng đủ các tiêu chí:
1. **Mã nguồn sạch:** Đã chạy `go fmt` và không có cảnh báo nghiêm trọng từ `go vet`.
2. **An toàn bộ nhớ & Concurrency:** Không tạo goroutine leak; các tương tác gọi WebKit/GTK phải được kiểm soát luồng an toàn.
3. **Kiểm thử biên dịch:** Chạy `go build` thành công trong môi trường devenv / nix shell.
4. **Kiểm thử đóng gói Nix:** Build thành công derivation qua `pkgs/assistant/default.nix`.
5. **Đồng bộ hóa tài liệu:** Cập nhật bảng công việc Sprint và nhật ký Daily Scrum.
