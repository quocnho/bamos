# SPRINT 10: Professional 3D Mascot Pet Library, Disney Animations & Frameless Floating Companion
**Thời gian:** 11/01/2027 - 25/01/2027 | **Trạng thái:** 🟢 COMPLETED | **Phiên bản:** `v01.10.00`

> 🎯 **Mục Tiêu Trọng Tâm Sprint 10:**
> Nâng cấp toàn diện tạo hình và thư viện hoạt cảnh của cún con Troly dựa trên bộ tài nguyên 3D cao cấp trong `/pkgs/troly/assets/pet/`:
> 1. **Thư viện hình ảnh & hoạt cảnh chuyên nghiệp (`PetMascotPetView.qml`):**
>    - Sử dụng trực tiếp bộ hình ảnh 3D Toon Render gốc: `cho chao.png` (vẫy tay chào), `cho dung.png` (đứng ngoan), `cho nhay.png` (nhảy tung tăng), `cho ngu.png` (cuộn tròn ngủ).
>    - Áp dụng 12 nguyên tắc Disney: Nhịp thở co giãn Squash & Stretch tự nhiên, hiệu ứng nảy Easing OutBounce khi chạm chuột, vẫy đuôi phấn khích.
>    - Cơ chế chuyển đổi trạng thái (FSM) với hiệu ứng Crossfade mượt mà.
> 2. **Trải nghiệm Desktop Pet Không Viền Hộp (Frameless & Transparent):**
>    - Cửa sổ nổi trong suốt hoàn toàn, không có viền hộp vuông hay khung cửa sổ cứng nhắc.
>    - Mặc định xuất hiện tại góc dưới bên phải màn hình khi khởi chạy lần đầu.
>    - Cho phép nắm kéo thả tự do đến mọi vị trí trên desktop và tự động ghi nhớ tọa độ `(x, y)` qua `QSettings`.
>    - Bong bóng thoại hoạt hình hiển thị lời chào cá nhân hóa theo xưng hô người dùng (`UserProfile.addressing`).
> 3. **Kiểm thử tự động & Đóng gói:**
>    - Đảm bảo 100% CTest suites passed (8/8) và đóng gói Nix derivation thành công.

---

## 📋 Bảng Công Việc (Sprint Backlog)

| Task ID | Component | Phân loại | Người nhận | Ước lượng | Trạng thái | Ghi chú kỹ thuật |
|---|---|---|---|---|---|---|
| `TROLY-1001` | Professional Pet View Component | `feat` | @AnimAgent, @DevOptAgent | 5 SP | 🟡 IN_PROGRESS | Xây dựng `PetMascotPetView.qml` tích hợp trọn bộ 3D assets & crossfade FSM |
| `TROLY-1002` | Disney Dynamics & Touch Interaction | `feat` | @AnimAgent | 5 SP | 🟡 IN_PROGRESS | 12 nguyên tắc hoạt hình Disney, Squash & Stretch, nảy OutBounce & tiếng sủa gâu gâu |
| `TROLY-1003` | Floating Desktop Pet Integration | `feat` | @DevOptAgent | 5 SP | 🟡 IN_PROGRESS | Tích hợp vào `main.qml`, kéo thả mượt mà, định vị góc dưới phải & lưu `QSettings` |
| `TROLY-1004` | Testing & NixOS Packaging | `test` | @DevOptAgent | 3 SP | 🟡 IN_PROGRESS | CTest 8/8 suites passed & `nix-build default.nix` |

---

## 👥 Ma Trận Phân Vai (RACI Sprint 10)
- **@PlanAgent:** Quản trị Backlog, tài liệu nghiệm thu Sprint 10.
- **@AnimAgent:** Thiết kế chuyển động 12 nguyên tắc Disney, phối hợp trạng thái cảm xúc chú cún.
- **@DevOptAgent:** Hiện thực mã nguồn QML/C++, kiểm thử CTest và đóng gói hệ thống NixOS.
