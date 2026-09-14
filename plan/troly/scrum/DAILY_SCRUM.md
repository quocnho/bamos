# NHẬT KÝ DAILY SCRUM: DỰ ÁN TROLY

Tài liệu ghi nhận nhịp độ làm việc, tiến độ hàng ngày và tháo gỡ điểm nghẽn (blockers) của hệ sinh thái Multi-Agent (@PlanAgent, @RdAgent, @DevOptAgent, @AnimAgent).

---

## [2026-09-14] (Khởi Động Dự Án & Chuẩn Hóa Hạ Tầng Agent)

### 📌 @PlanAgent (Project Manager & Documentation)
- **Hôm qua:** Hoàn tất nghiên cứu tài liệu [docs/troly/ARCHITECTURE.md](file:///etc/nixos/docs/troly/ARCHITECTURE.md) và cấu trúc Backlog F1-F7.
- **Hôm nay:** 
  - Khởi tạo cấu trúc hồ sơ Agile Scrum toàn diện trong `/plan/` (`BACKLOG.md`, `SPRINT_01.md`, `SPRINT_01_REVIEW.md`, `SPRINT_01_RETRO.md`, `DAILY_SCRUM.md`).
  - Thiết lập và đồng bộ các skills cho Antigravity IDE (`.agents/skills/` và `.antigravity/skills/`).
  - Chuẩn hóa tôn chỉ phân rã thư mục/tập tin Clean Architecture nhỏ nhất có thể (Atomic Granularity) trên toàn bộ hồ sơ Markdown và quy chuẩn Agent để tối ưu AI token.
  - **Định vị kiến trúc Package con & Flake cha:** Xác lập rõ ràng `troly` là package con của hệ thống Flake NixOS tại `/etc/nixos/` (tương tự `pkgs/assistant/` và `pkgs/bam/`). Cập nhật quy chuẩn nghiệm thu Definition of Done (DoD) bao gồm đóng gói derivation và kiểm thử toàn hệ thống qua lệnh `bam switch`.
  - **Kế thừa & Nâng cấp từ `/etc/nixos/pkgs/assistant/`:** Đọc lại toàn bộ mã nguồn `assistant` (Go/WebKitGTK), lập danh mục tính năng kế thừa đưa vào hồ sơ hệ thống: Hệ thống Menu, các cửa sổ thiết lập (RAG, LLM, System Inspector, WakaTracker, User Profile), cơ chế EyeLeo (3 mức nhắc nhở, idle Mutter), thanh bối cảnh thư mục (Bone Context) để chuẩn bị chuyển dịch sang Native C++20/Qt6.
- **Vướng mắc (Blockers):** Không có. Tiến độ đúng kế hoạch.

---

### 🔬 @RdAgent (R&D Specialist)
- **Hôm qua:** Phân tích giải pháp Hybrid Search (FTS5 + sqlite-vec) và Dynamic MoE Router (<30ms).
- **Hôm nay:** Đánh giá trade-off cấu hình VRAM/RAM khi chạy mô hình Qwen2.5-3B-Instruct lượng hóa Q4_K_M trên máy tính cá nhân.
- **Vướng mắc (Blockers):** Cần phối hợp với @DevOptAgent kiểm tra việc nạp thư viện `libvec0.so` trên môi trường NixOS.

---

### 💻 @DevOptAgent (Execution & CI/CD)
- **Hôm qua:** Cấu hình môi trường NixOS (`default.nix`, `shell.nix`, `devenv.nix`).
- **Hôm nay:** 
  - Khởi tạo git repository cho thư mục `troly`.
  - Xây dựng các Skeleton C++20 Clean Architecture theo nguyên tắc phân nhỏ nhất có thể (Atomic Granularity).
  - Khắc phục xung đột `qtquickcontrols2` trên Qt6 mới trong nixpkgs (`shell.nix`, `default.nix`, `devenv.nix`).
  - Hoàn thành đóng gói derivation và tích hợp flake cha `.#troly`.
  - Phát hành phiên bản chính thức `v01.01.00` lên GitHub.
  - **Hoàn thành toàn diện 100% Sprint 02 (`v01.02.00`):**
    - `TROLY-201` & `TROLY-202`: Cơ chế Núp lùm & Thò đuôi vẫy (Peek Tail), nút 🐾, morphing kích thước `84x120` ➔ `480x680`, hoạt ảnh vồ chuột và vẫy đuôi 12 nguyên tắc Disney.
    - `TROLY-203` & `TROLY-204`: Hệ thống bảo vệ mắt EyeLeo Native C++ (`EyeLeoService`, `EyeLeoViewModel`, `EyeLeoBreakOverlay.qml`), D-Bus Mutter idle detection.
    - `TROLY-205` & `TROLY-206`: Quick Menu ⚙️ 7 modal dialogs, DropArea kéo thả bối cảnh tệp/thư mục từ Nautilus vào `BoneContextBar.qml`.
    - `TROLY-207`: Viết unit test CTest `test_eyeleo.cpp` (100% Passed), `nix-build default.nix` thành công và `nix build .#troly --dry-run` từ flake gốc đạt 100%.
- **Vướng mắc (Blockers):** Không có. Toàn bộ tính năng Sprint 02 đã hoàn tất và sẵn sàng Review/Retro.

---

### 🎨 @AnimAgent (Lead 3D & Animation Director)
- **Hôm nay:** 
  - Thiết kế lớp phủ màn hình nghỉ ngơi `EyeLeoBreakOverlay.qml` hiển thị bộ đếm ngược kính mờ và biểu cảm cún con nhắc nhở bài tập mắt.
  - Hoàn tất hoạt ảnh Núp lùm thò đuôi vẫy đung đưa liên tục (xoay góc -12° đến 16° Easing InOutQuad).
  - Hiệu ứng Anticipation & Playful Jump vồ chuột khi cún thức giấc (`Easing.OutBack`, `Easing.OutBounce`).
- **Vướng mắc (Blockers):** Không có.
