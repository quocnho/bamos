# Quy Chuẩn Git Workflow, Commit Message & Phiên Bản Hóa (Dự Án Troly)

> 📦 **Bối Cảnh Hệ Thống & Flake Cha:** `troly` là một **package con** trong hệ sinh thái Flake NixOS tại `/etc/nixos/` (tương tự `/etc/nixos/pkgs/assistant/` và `/etc/nixos/pkgs/bam/`). Khi release hoặc cập nhật cấu hình hệ thống, việc đóng gói `nix build` và kiểm thử chuyển đổi bằng lệnh `bam switch` là một tiêu chí bắt buộc trong Definition of Done.
> 
> 🔄 **Bối Cảnh Dự Án:** `troly` được tái cấu trúc và phát triển nâng cấp từ `/etc/nixos/pkgs/assistant/`. Mọi commit và phiên bản phát hành đều hướng đến việc chuyển dịch hoàn hảo toàn bộ tính năng của `assistant` (Menu, Cửa sổ thiết lập, EyeLeo, WakaTracker,...) sang kiến trúc C++20/Qt6 Native.

Tài liệu này định nghĩa tiêu chuẩn toàn diện áp dụng cho package `troly`, bao gồm:
1. Quy tắc quản lý phiên bản 3 cấp (`vAA.BB.CC`).
2. Quy tắc đặt tên nhánh (Branch Naming).
3. Cấu trúc thông điệp commit (Why - What - Test).
4. Quy trình Release và Pull Request chuẩn Definition of Done (DoD).

---

## 1. Quy Chuẩn Đánh Số Phiên Bản (Versioning Strategy: AA.BB.CC)

Hệ thống quản lý phiên bản được chuẩn hóa theo định dạng 3 cấp độ: `vAA.BB.CC` (hoặc `AA.BB.CC`).

$$\mathbf{vAA\,.\,BB\,.\,CC}$$

| Cấp | Tên gọi | Định nghĩa & Điều kiện kích hoạt | Cơ chế tăng số |
| :--- | :--- | :--- | :--- |
| **AA** | **Major Version** | **Phiên bản lớn nhất:** Thay đổi kiến trúc hệ thống, breaking changes (không tương thích ngược), ra mắt bản thương mại hoặc thay đổi toàn bộ giao diện/core engine cốt lõi. | Khi `AA` tăng lên 1, reset `BB = 0` và `CC = 0` (ví dụ: `1.14.08` ➔ `2.00.00`). |
| **BB** | **Sprint Release** | **Phiên bản Sprint:** Tăng lên sau mỗi đợt chốt Sprint thành công khi code được merge/release vào nhánh `main` (cuối mỗi Sprint review/production deployment). Mỗi `BB` đại diện cho một gói tính năng hoàn chỉnh của một Sprint. | Tăng +1 vào cuối mỗi Sprint khi release lên `main`. Reset `CC = 0` (ví dụ: `1.04.12` ➔ `1.05.00`). |
| **CC** | **Task / Patch Update** | **Phiên bản cập nhật nhiệm vụ:** Tăng lên mỗi khi hoàn thành và gộp một Task, User Story, hoặc bản vá lỗi (Bug fix) từ Sprint Backlog vào nhánh tích hợp (`develop`). | Tăng +1 mỗi khi merge PR của một Task/Bug (ví dụ: `1.05.00` ➔ `1.05.01`). |

> **Quy tắc hiển thị:** Khuyến nghị dùng định dạng 2 chữ số cho BB và CC (`AA.BB.CC`, ví dụ `1.01.00`) để sắp xếp thư mục, tag và log luôn đồng nhất.

---

## 2. Quy Tắc Đặt Tên Nhánh (Branch Naming)

Mỗi nhánh làm việc bắt buộc phải gắn liền với Ticket ID từ Sprint Backlog và tuân theo phân loại chuẩn:

### Cú pháp:
`<type>/<ticket-id>-<short-description>`

### Bảng phân loại `type`:
| Type | Mục đích | Ví dụ |
| :--- | :--- | :--- |
| `feat` | Phát triển User Story / Tính năng mới | `feat/TROLY-103-domain-entities` |
| `fix` | Sửa bug trong phạm vi Sprint | `fix/TROLY-112-qml-transparency` |
| `hotfix` | Sửa lỗi khẩn cấp trực tiếp từ `main` | `hotfix/TROLY-999-crash-on-model-unload` |
| `refactor` | Cải tiến code/kiến trúc (không đổi logic nghiệp vụ) | `refactor/TROLY-104-sqlite-rag-interface` |
| `spike` | Nghiên cứu kỹ thuật, POC trước Sprint | `spike/TROLY-301-evaluate-qwen-coder` |
| `chore` | Nâng cấp dependencies, cấu hình CI/CD | `chore/TROLY-101-nixos-devenv` |

---

## 3. Cấu Trúc Commit Message (Why - What - Test)

Mỗi commit (hoặc squash commit của một PR) phải tuân theo cấu trúc phân tầng kết hợp **Conventional Commits** và bối cảnh **Agile Scrum**.

### Mẫu khung chuẩn:

```text
<type>(<TICKET-ID>): <short summary> [vAA.BB.CC]

[WHY / BUSINESS CONTEXT]
- Nêu rõ bối cảnh nghiệp vụ (User Story narrative) hoặc nguyên nhân gốc (root cause).
- Vấn đề gặp phải nếu không áp dụng thay đổi này.

[WHAT / SCOPE OF CHANGE]
- Tóm tắt các thay đổi kỹ thuật ở mức tổng quan (high-level).
- Không liệt kê chi tiết từng dòng code.

[TEST / DEFINITION OF DONE]
- [x] Acceptance Criteria (AC) đã pass.
- [x] Kết quả Unit / Integration tests.
- [x] Các ca kiểm thử thủ công/edge-cases đã kiểm chứng.

Closes: <TICKET-ID>
```

---

## 4. Quy Trình Release & Tiêu Chí Hoàn Thành (Definition of Done - DoD)

Một Task hoặc Sprint Release chỉ được xem là hoàn thành khi:
1. **Mã nguồn sạch:** Tuân thủ Clean Architecture C++20, quản lý con trỏ RAII tuyệt đối, zero compiler warnings.
2. **Kiểm thử tự động:** Unit tests và CTest vượt qua 100%, kiểm tra rò rỉ bộ nhớ với AddressSanitizer (ASAN).
3. **Kiểm thử Giao diện & Live Preview (Bắt buộc sau mỗi lần build):**
   - Chạy thử nhị phân (`./build/troly` hoặc `./result/bin/troly`) hoặc Live Preview QML (`qml6 src/presentation/ui/main.qml`).
   - Xác nhận cửa sổ nổi trong suốt hiển thị đúng tọa độ, cún Mascot có cử động sống động (Squash & Stretch), không crash hoặc lỗi QML binding.
4. **Đóng gói Nix Package & Kiểm thử Hệ thống:**
   - Đóng gói derivation cục bộ (`nix-build -E 'with import <nixpkgs> {}; callPackage ./default.nix {}'`) thành công 100%.
   - Kiểm thử chuyển đổi hệ thống BamOS/NixOS qua lệnh `bam dry` / `bam switch` hoạt động trơn tru không lỗi.
5. **Tài liệu & Hồ sơ:** Được cập nhật vào Sprint Tracker (`sprints/sprint-XX/PLAN.md`) và đồng bộ nhật ký Daily Scrum (`scrum/DAILY_SCRUM.md`) bởi `@PlanAgent`.
6. **Hiệu năng:** Duy trì 60 FPS trên Qt6 Scene Graph Wayland, tiêu thụ 0.0% CPU khi ở chế độ ngủ sâu (`cho ngu.svg`).
