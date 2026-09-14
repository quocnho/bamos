# SPRINT REVIEW: Sprint 02 - Modern Mascot UI & EyeLeo Native
**Thời gian:** 15/09/2026 - 29/09/2026 | **Người chủ trì:** @PlanAgent | **Trạng thái:** 🟢 COMPLETED | **Phiên bản nghiệm thu:** `v01.02.00`

> 🎯 **Mục tiêu Sprint 02:**
> Hiện thực hóa trọn vẹn trải nghiệm người dùng tương tác với Desktop Pet Troly: cơ chế Núp lùm thò đuôi vẫy (Peek Tail), hoạt ảnh 12 nguyên tắc Disney, hệ thống bảo vệ mắt EyeLeo Native C++ (3 mức cảnh báo, D-Bus Mutter idle detection), Menu 7 modal cài đặt và bối cảnh thư mục Bone Context kéo thả từ Nautilus.

---

## 1. Bảng Nghiệm Thu Các Hạng Mục Bàn Giao (Delivered Items)

| Task ID | Thành phần | Phân loại | Người thực hiện | Đánh giá DoD | Kết quả nghiệm thu |
|---|---|---|---|---|---|
| `TROLY-201` | Mascot Interaction & Peek Tail | `feat` | @AnimAgent, @DevOptAgent | 🟢 PASSED | Nút `🐾`, cơ chế Núp lùm thò đuôi vẫy, click đuôi thức giấc & morphing cửa sổ `84x120` ➔ `480x680` |
| `TROLY-202` | Disney Animation & FSM Refining | `feat` | @AnimAgent | 🟢 PASSED | Máy trạng thái Mascot FSM (`peek_tail` ➔ `playful_jump` ➔ `greeting` ➔ `idle`), 100% Bezier easing |
| `TROLY-203` | Native EyeLeo Service & Controller | `feat` | @DevOptAgent | 🟢 PASSED | `EyeLeoService` C++ quản lý 3 mức timer (cảnh báo 30s, nghỉ ngắn 20s, nghỉ dài 5m), D-Bus Mutter idle detection |
| `TROLY-204` | EyeLeo UI Modals & Exercises | `feat` | @DevOptAgent, @AnimAgent | 🟢 PASSED | Lớp phủ kính mờ `EyeLeoBreakOverlay.qml`, bài tập mắt cùng cún con, đếm ngược và Strict Mode |
| `TROLY-205` | Quick Action Menu & Modals Wiring | `feat` | @DevOptAgent | 🟢 PASSED | Nút ⚙️ mở Menu thả xuống, kết nối 7 modal settings, bọc fallback an toàn chống lỗi preview |
| `TROLY-206` | Bone Context Bar & Nautilus Dnd | `feat` | @DevOptAgent | 🟢 PASSED | `DropArea` thông minh toàn cửa sổ: kéo thả thư mục gán vào Bone Context, kéo thả file gán vào đính kèm |
| `TROLY-207` | Unit Test & Verification | `test` | @DevOptAgent | 🟢 PASSED | Tạo `tests/test_eyeleo.cpp`, CTest tự động 100% Passed, `nix-build default.nix` & `nix build .#troly --dry-run` |

---

## 2. Bằng Chứng Kỹ Thuật (Demo & Artifacts)
- **Kiểm thử tự động CTest:** `EyeLeoTests` pass 100% trong 0.02s.
- **Đóng gói Nix Package:** Derivation `/nix/store/h1zwf8v8ks97wii3kilv7vsnrx7grgvi-troly-0.1.0` hoàn tất.
- **Tương thích Flake:** Kiểm tra `nix build .#troly --dry-run` từ `/etc/nixos` hợp lệ hoàn toàn.
- **Live Preview & Binary:** `just tp` (Live QML Preview) và `just tr` (Native C++ Runtime) đều hoạt động ổn định.

---

## 3. Chuyển Giao Sang Sprint 03 (`v01.03.00`)
- Mục tiêu tiếp theo: **F1 Vector RAG & SQLite WAL Engine**.
- Khởi tạo bảng DDL chuẩn, nạp extension `sqlite-vec` (`libvec0.so`), bộ phân mảnh văn bản bất đồng bộ `std::jthread` và thuật toán Hybrid Search Reciprocal Rank Fusion (RRF).
