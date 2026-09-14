# NHẬT KÝ DAILY SCRUM: DỰ ÁN TROLY

Tài liệu ghi nhận nhịp độ làm việc, tiến độ hàng ngày và tháo gỡ điểm nghẽn (blockers) của hệ sinh thái Multi-Agent (@PlanAgent, @RdAgent, @DevOptAgent).

---

## [2026-09-14] (Khởi Động Dự Án & Chuẩn Hóa Hạ Tầng Agent)

### 📌 @PlanAgent (Project Manager & Documentation)
- **Hôm qua:** Hoàn tất nghiên cứu tài liệu [docs/ARCHITECTURE.md](file:///etc/nixos/pkgs/troly/docs/ARCHITECTURE.md) và cấu trúc Backlog F1-F7.
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
  - Tiến hành xây dựng các Skeleton C++20 Clean Architecture trong `src/domain/` và `src/usecases/` theo nguyên tắc phân nhỏ nhất có thể (Atomic Granularity: chia nhỏ entities, value objects, interfaces) giúp tiết kiệm token khi đọc mã nguồn.
  - Khắc phục xung đột `qtquickcontrols2` trên Qt6 mới trong nixpkgs (`shell.nix`, `default.nix`, `devenv.nix`).
  - Lọc bỏ thư mục build/cache qua `cleanSourceWith` trong `default.nix`, đảm bảo lệnh `nix-build` và `ninja -C build` biên dịch thành công 100%.
  - Tích hợp và tài liệu hóa quy trình đóng gói trong hệ sinh thái Flake tổng thể tại `/etc/nixos/`, kiểm thử cập nhật hệ thống với lệnh `bam switch` (công cụ CLI của `/etc/nixos/pkgs/bam/`).
  - Thiết lập quy chuẩn bắt buộc: sau mỗi lần build hoàn thành, lập tức chạy thử ứng dụng (`./build/troly` hoặc `qml6 src/presentation/ui/main.qml`) để kiểm tra trực quan giao diện nổi, độ trong suốt Scene Graph và trạng thái animation cún cưng trước khi nghiệm thu.
- **Vướng mắc (Blockers):** Đã giải quyết toàn bộ blockers về môi trường biên dịch.

---

### 🎨 @AnimAgent (Lead 3D & Animation Director)
- **Hôm qua:** Tiếp nhận bộ assets vector SVG biểu cảm thú cưng trong `assets/pet/`.
- **Hôm nay:** 
  - Thiết lập tiêu chuẩn hoạt hình 12 nguyên tắc Disney và cấu trúc máy trạng thái Mascot FSM.
  - Xây dựng bộ kỹ năng `mascot-animation-director` phục vụ thiết kế cử động, Easing Bezier và tối ưu Scene Graph 60fps.
  - Tích hợp thành công Mascot Pet Sprite Banner vào `main.qml` với 4 trạng thái linh hoạt (`idle` với Squash & Stretch nhịp thở tự nhiên, `excited` khi AI đang suy luận/nói, `sleep` tiết kiệm 0% CPU, và `greeting` khi chạm tương tác).
  - Lập lộ trình kỹ thuật chuẩn bị tích hợp Realtime 3D Mesh (glTF/Qt Quick 3D) cho các pha tiếp theo.
- **Vướng mắc (Blockers):** Không còn blocker. Sẵn sàng tích hợp tiếp bộ bài tập mắt EyeLeo.

---

## [2026-09-14 Buổi Chiều] (Rà Soát, Đồng Bộ Flake Cha & Tối Ưu Hóa Giao Diện)

### 📌 @PlanAgent (Project Manager & Documentation)
- **Hôm nay:**
  - Di chuyển và quản lý tập trung toàn bộ 9 Skills của hệ thống lên `/etc/nixos/.agents/skills/`, loại bỏ trùng lặp trong `pkgs/troly/`.
  - Cập nhật tài liệu kiến trúc [docs/ANTIGRAVITY_SETUP.md](file:///etc/nixos/pkgs/troly/docs/ANTIGRAVITY_SETUP.md), [sprint-01/REVIEW.md](file:///etc/nixos/pkgs/troly/plan/sprints/sprint-01/REVIEW.md).
  - Nghiệm thu 100% các tiêu chí của Sprint 01 (`TROLY-101` đến `TROLY-106`).
- **Vướng mắc (Blockers):** Không có.

### 💻 @DevOptAgent (Execution & CI/CD)
- **Hôm nay:**
  - Kiểm tra tính toàn vẹn của build cục bộ: `ninja -C build` và `nix-build -E 'with import <nixpkgs> {}; callPackage ./default.nix {}'` biên dịch thành công hoàn hảo.
  - Khai báo và tích hợp `troly` vào `packages.${system}.troly` trong file Flake mẹ `/etc/nixos/flake.nix`.
  - Kiểm thử `nix build .#troly --dry-run` từ thư mục mẹ `/etc/nixos/` đảm bảo tính tương thích hệ thống tuyệt đối.
  - Bổ sung nút tương tác nhanh cho bài tập mắt trong modal EyeLeo.
- **Vướng mắc (Blockers):** Hệ thống sẵn sàng cho Sprint 02.
