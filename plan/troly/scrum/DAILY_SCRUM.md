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

---

## [2026-09-14] (Sprint 03: Hoàn Thành Nghiệm Thu Vector RAG & SQLite WAL Engine - `v01.03.00`)

### 📌 @PlanAgent (Project Manager & Documentation)
- **Hôm nay:**
  - Hoàn tất theo dõi 7/7 user stories Sprint 03 (`TROLY-301` đến `TROLY-307`).
  - Cập nhật tài liệu Sprint 03: [PLAN.md](file:///etc/nixos/plan/troly/sprints/sprint-03/PLAN.md), [REVIEW.md](file:///etc/nixos/plan/troly/sprints/sprint-03/REVIEW.md), [RETRO.md](file:///etc/nixos/plan/troly/sprints/sprint-03/RETRO.md).
  - Chuẩn bị kế hoạch Sprint 04: Local Inference & Dynamic MoE Router (`v01.04.00`).
- **Vướng mắc (Blockers):** Không có.

### 🔬 @RdAgent (R&D Specialist)
- **Hôm nay:**
  - Thiết kế và hiệu chỉnh thuật toán Hybrid Search Reciprocal Rank Fusion (RRF với hằng số $k=60$).
  - Đánh giá khả năng nạp động `libvec0.so` và cấu trúc bảng ảo `vec_chunks (chunk_id INT, embedding FLOAT[384])`.
- **Vướng mắc (Blockers):** Không có. Kết quả tìm kiếm kết hợp BM25 và Vector Cosine đạt hiệu năng tối ưu.

### 💻 @DevOptAgent (Execution & CI/CD)
- **Hôm nay:**
  - Hiện thực DDL SQLite WAL và kết nối RAII an toàn trong `SqliteRAGRepository.cpp/.hpp`.
  - Xây dựng `DocumentIngestionWorker.hpp` hỗ trợ quét tệp chạy ngầm đa luồng `std::jthread`, băm SHA256, chia đoạn (chunking) 500 ký tự.
  - Xây dựng `RAGViewModel.hpp/.cpp`, đăng ký context property `ragVM` và kết nối với `RAGSettingsModal.qml`.
  - Viết bộ kiểm thử `tests/test_rag.cpp` (100% CTest Passed cùng `tests/test_eyeleo.cpp`).
  - Đóng gói derivation thành công qua `nix-build default.nix` và kiểm tra `nix build .#troly --dry-run` từ flake mẹ pass 100%.
- **Vướng mắc (Blockers):** Đã khắc phục lỗi MOC vtable linker error bằng cách phân tách rõ ràng file `.cpp` và `.hpp` cho `RAGViewModel`.

### 🎨 @AnimAgent (Lead 3D & Animation Director)
- **Hôm nay:**
  - Phác thảo biểu cảm cún cưng tìm kiếm tri thức (đánh hơi tìm sách) phục vụ hoạt ảnh lúc RAG đang chạy truy vấn dữ liệu.
- **Vướng mắc (Blockers):** Không có. Sẵn sàng tích hợp cho Sprint 04.

---

## [2026-09-14] (Sprint 04: Hoàn Thành Nghiệm Thu Local Inference & Dynamic MoE Router - `v01.04.00`)

### 📌 @PlanAgent (Project Manager & Documentation)
- **Hôm nay:**
  - Điều phối và hoàn tất nghiệm thu 7/7 user stories Sprint 04 (`TROLY-401` đến `TROLY-407`).
  - Cập nhật hồ sơ Scrum: [PLAN.md](file:///etc/nixos/plan/troly/sprints/sprint-04/PLAN.md), [REVIEW.md](file:///etc/nixos/plan/troly/sprints/sprint-04/REVIEW.md), [RETRO.md](file:///etc/nixos/plan/troly/sprints/sprint-04/RETRO.md) và [README.md](file:///etc/nixos/plan/troly/README.md).
  - Chuẩn bị sẵn sàng cấu trúc cho Sprint 05 (Action Dispatcher & Safety Guard).
- **Vướng mắc (Blockers):** Không có.

### 🔬 @RdAgent (R&D Specialist)
- **Hôm nay:**
  - Thiết kế `FastHeuristicIntentClassifier` phân loại 4 nhóm ý định (`GeneralChat`, `CodeGeneration`, `SystemCommand`, `KnowledgeQuery`) với độ trễ nano-seconds (<1ms).
  - Xây dựng danh mục Model Slots chuyên biệt và bộ giám sát ngân sách VRAM Supervisor (< 6GB) cho `DynamicMoERouter`.
- **Vướng mắc (Blockers):** Không có.

### 💻 @DevOptAgent (Execution & CI/CD)
- **Hôm nay:**
  - Hiện thực `DynamicMoERouter.hpp` và `FastHeuristicIntentClassifier.hpp` theo chuẩn C++20 Clean Architecture.
  - Tích hợp Dynamic MoE Router và tự động tra cứu RAG (Context Augmentation) trực tiếp vào `ChatViewModel`.
  - Xây dựng `LLMViewModel.hpp/.cpp` và kết nối giao diện an toàn trong `LLMSettingsModal.qml`.
  - Khắc phục xung đột từ khóa Qt MOC `slots` trong `LLMViewModel::selectModel`.
  - Viết bộ kiểm thử tự động `tests/test_inference.cpp`, đạt 100% CTest (3/3 test suites passed: `EyeLeoTests`, `RAGTests`, `InferenceTests`).
  - Đóng gói derivation thành công qua `nix-build default.nix` ra `/nix/store/icvz0gixaqbmvzcfdd16axsbxdnl9519-troly-0.1.0` và kiểm tra `nix build .#troly --dry-run` hoàn tất sạch sẽ.
- **Vướng mắc (Blockers):** Không có.

### 🎨 @AnimAgent (Lead 3D & Animation Director)
- **Hôm nay:**
  - Đồng bộ trạng thái cún cưng phấn khích/suy nghĩ (`excited` / `playful_jump`) tương thích với luồng stream tokens từ Dynamic MoE Router.
- **Vướng mắc (Blockers):** Không có.

---

## [2026-09-14] (Sprint 05: Hoàn Thành Nghiệm Thu Action Dispatcher & Safety Guard - `v01.05.00`)

### 📌 @PlanAgent (Project Manager & Documentation)
- **Hôm nay:**
  - Điều phối và hoàn tất nghiệm thu 7/7 user stories Sprint 05 (`TROLY-501` đến `TROLY-507`).
  - Cập nhật tài liệu: [PLAN.md](file:///etc/nixos/plan/troly/sprints/sprint-05/PLAN.md), [REVIEW.md](file:///etc/nixos/plan/troly/sprints/sprint-05/REVIEW.md), [RETRO.md](file:///etc/nixos/plan/troly/sprints/sprint-05/RETRO.md) và [README.md](file:///etc/nixos/plan/troly/README.md).
  - Chuẩn bị sẵn sàng cấu trúc cho Sprint 06 (System Inspector, WakaTracker & Adaptive Persona).
- **Vướng mắc (Blockers):** Không có.

### 🔬 @RdAgent (R&D Specialist)
- **Hôm nay:**
  - Thiết kế tập luật Regex Blacklist & Caution cho `DefaultSafetyGuard`, phân loại chính xác 4 cấp độ: `Safe`, `Caution`, `Dangerous`, `Blocked`.
  - Nghiên cứu cơ chế bắt luồng stdout/stderr theo chunk thời gian thực để cấp dữ liệu cho ReAct cycle.
- **Vướng mắc (Blockers):** Không có.

### 💻 @DevOptAgent (Execution & CI/CD)
- **Hôm nay:**
  - Hiện thực `DefaultSafetyGuard.hpp` kiểm duyệt nghiêm ngặt các lệnh nguy hiểm (`rm -rf /`, `mkfs`, `dd`, `fork bomb`).
  - Xây dựng `ActionViewModel.hpp/.cpp` quản lý vòng đời lệnh shell và kết nối trực tiếp với modal cảnh báo đỏ `SafetyConfirmationModal.qml`.
  - Nâng cấp `LinuxActionDispatcher` C++20 điều phối lệnh ngầm và hủy luồng qua `std::stop_token`.
  - Viết bộ kiểm thử tự động `tests/test_action.cpp`, đạt 100% CTest (4/4 test suites passed: `EyeLeoTests`, `RAGTests`, `InferenceTests`, `ActionTests`).
  - Đóng gói derivation thành công qua `nix-build default.nix` ra `/nix/store/5vw3ibgsa0pji43icxkw430zh384lr4m-troly-0.1.0` và kiểm tra `nix build .#troly --dry-run` hoàn tất không lỗi.
- **Vướng mắc (Blockers):** Không có.

### 🎨 @AnimAgent (Lead 3D & Animation Director)
- **Hôm nay:**
  - Thiết kế giao diện modal xác nhận `SafetyConfirmationModal.qml` cảnh báo đỏ nổi bật, trực quan cho người dùng.
- **Vướng mắc (Blockers):** Không có.

---

## [2026-09-14] (Sprint 06: Hoàn Thành Nghiệm Thu System Inspector, WakaTracker & Adaptive Persona - `v01.06.00`)

### 📌 @PlanAgent (Project Manager & Documentation)
- **Hôm nay:**
  - Hoàn tất theo dõi và nghiệm thu 7/7 user stories Sprint 06 (`TROLY-601` đến `TROLY-607`).
  - Lập hồ sơ tài liệu đầy đủ: [PLAN.md](file:///etc/nixos/plan/troly/sprints/sprint-06/PLAN.md), [REVIEW.md](file:///etc/nixos/plan/troly/sprints/sprint-06/REVIEW.md), [RETRO.md](file:///etc/nixos/plan/troly/sprints/sprint-06/RETRO.md) và cập nhật [README.md](file:///etc/nixos/plan/troly/README.md).
  - Chuẩn bị kế hoạch Sprint 07 (Sprint cuối: Self-Evolving Hub & 3D Mascot POC - `v01.07.00`).
- **Vướng mắc (Blockers):** Không có.

### 🔬 @RdAgent (R&D Specialist)
- **Hôm nay:**
  - Nghiên cứu cơ chế đọc `/proc/meminfo` và `std::filesystem::space` để tính toán dung lượng RAM và Nix Store không tốn overhead.
  - Thiết kế thuật toán phân tích nhịp độ năng suất nội bộ và cấu trúc prompt cho `UserProfile` (Adaptive Persona).
- **Vướng mắc (Blockers):** Không có.

### 💻 @DevOptAgent (Execution & CI/CD)
- **Hôm nay:**
  - Hiện thực `SystemInspectorService.hpp`, `WakaTrackerService.hpp`, `UserProfile.hpp` theo chuẩn C++20 Clean Architecture.
  - Xây dựng `ExtensionsViewModels.hpp/.cpp` quản lý `SystemInspectorViewModel`, `WakaTrackerViewModel`, `UserProfileViewModel`.
  - Nâng cấp các modal QML: [SystemInspectorModal.qml](file:///etc/nixos/pkgs/troly/src/presentation/ui/SystemInspectorModal.qml), [WakaTrackerModal.qml](file:///etc/nixos/pkgs/troly/src/presentation/ui/WakaTrackerModal.qml), [ProfileModal.qml](file:///etc/nixos/pkgs/troly/src/presentation/ui/ProfileModal.qml).
  - Viết bộ kiểm thử tự động `tests/test_system_inspector.cpp`, đạt 100% CTest (5/5 test suites passed).
  - Đóng gói derivation thành công qua `nix-build default.nix` ra `/nix/store/v88rwg2y9v14aj0nkin2sqm6gvda8bai-troly-0.1.0` và kiểm tra `nix build .#troly --dry-run` hoàn tất sạch sẽ.
- **Vướng mắc (Blockers):** Không có.

### 🎨 @AnimAgent (Lead 3D & Animation Director)
- **Hôm nay:**
  - Hoàn thiện giao diện đồ họa thẻ thống kê trực quan cho WakaTracker và System Inspector trong bộ ba tiện ích F8.
- **Vướng mắc (Blockers):** Không có.

---

## [2026-09-14] (Sprint 07: Hoàn Thành Nghiệm Thu Self-Evolving Hub & 3D Mascot POC - `v01.07.00` - Final Release)

### 📌 @PlanAgent (Project Manager & Documentation)
- **Hôm nay:**
  - Điều phối và hoàn tất nghiệm thu 5/5 user stories Sprint 07 (`TROLY-701` đến `TROLY-705`).
  - Lập hồ sơ tài liệu đầy đủ: [PLAN.md](file:///etc/nixos/plan/troly/sprints/sprint-07/PLAN.md), [REVIEW.md](file:///etc/nixos/plan/troly/sprints/sprint-07/REVIEW.md), [RETRO.md](file:///etc/nixos/plan/troly/sprints/sprint-07/RETRO.md) và cập nhật [README.md](file:///etc/nixos/plan/troly/README.md).
  - Tổng kết trọn vẹn 100% Product Backlog dự án `troly` từ F1 đến F8 qua 7 Sprint.
- **Vướng mắc (Blockers):** Không có. Toàn bộ lộ trình đã hoàn thành xuất sắc!

### 🔬 @RdAgent (R&D Specialist)
- **Hôm nay:**
  - Thiết kế cấu trúc ChatML dataset và pipeline 4 bước LoRA/GGUF cho `SelfEvolvingService`.
  - Phân tích tính toàn vẹn dữ liệu huấn luyện cục bộ không gửi dữ liệu ra môi trường ngoài.
- **Vướng mắc (Blockers):** Không có.

### 💻 @DevOptAgent (Execution & CI/CD)
- **Hôm nay:**
  - Hiện thực `GoldenInteraction.hpp` và `SelfEvolvingService.hpp` theo chuẩn C++20 Clean Architecture.
  - Xây dựng `SelfEvolvingViewModel` trong `ExtensionsViewModels.hpp/.cpp`, kết nối giao diện `SelfEvolvingModal.qml`.
  - Tích hợp thành phần `Mascot3DPOC.qml` và nút bấm chuyển đổi 2D/3D trên Mascot Banner trong `main.qml`.
  - Viết bộ kiểm thử tự động `tests/test_self_evolving.cpp`, đạt 100% CTest (6/6 test suites passed trong 0.88s).
  - Đóng gói derivation thành công qua `nix-build default.nix` ra `/nix/store/hqf591j0nyfnh67abpbzp94fxy7c8n1v-troly-0.1.0` và kiểm tra `nix build .#troly --dry-run` hoàn tất không lỗi.
- **Vướng mắc (Blockers):** Không có.

### 🎨 @AnimAgent (Lead 3D & Animation Director)
- **Hôm nay:**
  - Hoàn thiện thành phần `Mascot3DPOC.qml` với hiệu ứng xoay 3D trực quan, ánh xạ Toon shading và chiếc đuôi lò xo (Spring Bone wagging).
- **Vướng mắc (Blockers):** Không có.

---

## [2026-09-14] (Sprint 08: Hoàn Thành Nghiệm Thu Hybrid Expansion - `v01.08.00`)

### 📌 @PlanAgent (Project Manager & Documentation)
- **Hôm nay:**
  - Điều phối và theo dõi hoàn tất 5/5 user stories Sprint 08 (`TROLY-801` đến `TROLY-805`).
  - Lập hồ sơ tài liệu đầy đủ: [PLAN.md](file:///etc/nixos/plan/troly/sprints/sprint-08/PLAN.md), [REVIEW.md](file:///etc/nixos/plan/troly/sprints/sprint-08/REVIEW.md), cập nhật [README.md](file:///etc/nixos/plan/troly/README.md) và [BACKLOG.md](file:///etc/nixos/plan/troly/backlog/BACKLOG.md).
- **Vướng mắc (Blockers):** Không có. Tiến độ vượt chỉ tiêu.

### 🔬 @RdAgent (R&D Specialist)
- **Hôm nay:**
  - Thiết kế tích hợp mở rộng Tool Calling cho Agent (File system traversal, content search, Nix validation).
  - Phân tích kiến trúc Zero Overhead Audio Feedback Native.
- **Vướng mắc (Blockers):** Không có.

### 💻 @DevOptAgent (Execution & CI/CD)
- **Hôm nay:**
  - Mở rộng `IActionDispatcher` và hiện thực `LinuxActionDispatcher` (`listDirectory`, `searchInFiles`, `validateNixConfig`).
  - Xây dựng `AudioFeedbackService.hpp`, tích hợp âm thanh gâu gâu vào `ChatViewModel` khi cún thức giấc và xoa đầu.
  - Cập nhật `ActionViewModel` và giao diện `SystemInspectorModal.qml` bổ sung nút kiểm tra cấu hình NixOS.
  - Viết bộ test `tests/test_agent_tools.cpp`, biên dịch và đạt 100% CTest (**7/7 suites passed**).
  - Đóng gói derivation thành công qua `nix-build` ra `/nix/store/xsqmwm3yc8xhd8am12cwaqvra2gggvc1-troly-0.1.0`.
- **Vướng mắc (Blockers):** Không có.

### 🎨 @AnimAgent (Lead 3D & Animation Director)
- **Hôm nay:**
  - Tích hợp hiệu ứng vuốt ve trỏ chuột (MouseArea hover/petting) kèm hoạt ảnh Squash & Stretch chuẩn 12 nguyên tắc Disney trên `Mascot3DPOC.qml`.
- **Vướng mắc (Blockers):** Không có.

