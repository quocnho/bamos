# 🚀 Troly (Trợ Lý) — Native Edge AI Desktop Companion

> **Troly** là ứng dụng trợ lý ảo Desktop thế hệ mới dành cho hệ điều hành **NixOS** (và Linux Wayland). Được thiết kế theo triết lý **Air-gapped 100% Cục Bộ**, **Zero Web Overhead**, kết hợp **Clean Architecture C++20**, **Qt6 Quick Scene Graph** và hệ thống suy luận mô hình ngôn ngữ nhỏ cục bộ (**llama.cpp** + **Dynamic MoE Router**).
> 
> 🔄 **Nguồn gốc & Tái cấu trúc:** Dự án này được tái cấu trúc, phát triển và nâng cấp trực tiếp từ dự án gốc tại `/etc/nixos/pkgs/assistant/`. Hệ thống kế thừa toàn bộ tri thức, logic nghiệp vụ từ `assistant`, đồng thời tái sử dụng và tối ưu hóa các thành phần cốt lõi: hệ thống Menu thao tác nhanh, các cửa sổ thiết lập đa năng (RAG, LLM, System Inspector, WakaTracker, User Profile), cơ chế nhắc nhở bảo vệ mắt EyeLeo (cảnh báo 30s, nghỉ ngắn 20-20-20, nghỉ dài, strict mode, phát hiện idle D-Bus Mutter), thanh bối cảnh thư mục (Bone Context), chuyển hóa hoàn toàn từ Go/WebKitGTK sang C++20/Qt6 Native 60fps.

---

## 🐶 Tầm Nhìn & Ý Tưởng Sản Phẩm (Product Vision & Persona)

**Troly** không chỉ là một thanh công cụ khô khan mà hiện diện như một **chú cún con ảo (Desktop Pet / Mascot)** nhỏ nhắn, nhí nhảnh, thông minh, vui vẻ và vô cùng dễ thương sống động ngay trên màn hình máy tính của bạn.

### 🐕 1. Ngoại hình & Hành vi tương tác ngộ nghĩnh (Desktop Pet UI/UX)
- **Tự do di chuyển & tương tác môi trường:** Chú cún có thể chạy nhảy khắp màn hình, leo trèo bám lên các cạnh cửa sổ, thanh taskbar, menu panel hoặc núp sau các cửa sổ đang mở với những biểu cảm tinh nghịch.
- **Tính năng "Núp lùm & Lò đuôi":** Cún có thể ẩn mình vào sát mép phải màn hình (cả người nằm ẩn sang workspace ảo bên cạnh) và chỉ để thò chiếc đuôi nhỏ vẫy vẫy.
- **Tương tác chuột (Playful Wakeup):** Khi người dùng rê chuột click vào chiếc đuôi, cún con sẽ bất ngờ giật mình vui sướng, quay ngoắt lại cắn nhẹ vào con trỏ chuột như gặp lại chủ nhân sau bao ngày mong ngóng, cất tiếng sủa thân thiện: `Gâu gâu, em chào chủ nhân/anh/chị!` kèm khung nhập lệnh (Input Box) tức thì.

#### 🐾 Các Trạng Thái Biểu Cảm Của Cún Cưng (`assets/pet/`):
| Chào Đón / Vẫy Đuôi | Chờ Lệnh / Đứng Canh | Vui Đùa / Nhảy Nhót | Ngủ Say / Tiết Kiệm Pin |
| :---: | :---: | :---: | :---: |
| <img src="assets/pet/cho%20chao.svg" width="160" alt="Chó Chào" /> | <img src="assets/pet/cho%20dung.svg" width="160" alt="Chó Đứng" /> | <img src="assets/pet/cho%20nhay.svg" width="160" alt="Chó Nhảy" /> | <img src="assets/pet/cho%20ngu.svg" width="160" alt="Chó Ngủ" /> |
| `cho chao.svg` | `cho dung.svg` | `cho nhay.svg` | `cho ngu.svg` |
| Chào buổi sáng & vẫy đuôi | Chờ lệnh & bảo vệ hệ thống | Tương tác chuột & phản hồi | Chế độ nghỉ & ngủ sâu |

#### 🎬 Tiêu Chuẩn Hoạt Hình & Kỹ Thuật Đồ Họa Realtime (Animation & 3D Game Pipeline):
- **12 Nguyên Tắc Hoạt Hình Disney:** Mọi biểu cảm và cử động của cún cưng đều được chỉ đạo nghệ thuật chặt chẽ:
  - **Squash & Stretch & Anticipation:** Khi nhún nhảy đón chuột, cún có động tác lắc mông lấy đà (Anticipation) và co giãn thể tích mềm mại (Squash & Stretch).
  - **Secondary Action & Overlapping:** Đôi tai bồng bềnh và chỏm đuôi đung đưa có độ trễ tự nhiên theo gia tốc chuyển động.
  - **Bezier Easing:** Tuyệt đối không dùng chuyển động tuyến tính thô cứng; 100% chuyển động dùng đường cong Bezier (`Easing.OutBack`, `Easing.InOutQuad`).
- **Mascot Finite State Machine (FSM):** Máy trạng thái chuyển đổi mượt mà giữa các hành vi: `GREETING` ➔ `IDLE_STAND` ➔ `PLAYFUL_JUMP` ➔ `PEEK_TAIL` (Núp lùm) ➔ `DEEP_SLEEP`.
- **Tối ưu 60FPS Wayland & Tiết kiệm năng lượng:**
  - Rasterize SVG ở kích thước thực tế (`sourceSize: Qt.size(w,h)`), texture caching trên Scene Graph.
  - Khi cún ngủ say (`cho ngu.svg`), ngắt render timer để CPU/GPU tiêu thụ tiệm cận 0.0%.
- **Lộ trình nâng cấp Realtime 3D (glTF / Qt Quick 3D):** Kiến trúc sẵn sàng hỗ trợ nạp mô hình 3D cách điệu (Stylized Mesh, Toon Shading, Spring Bone Rigging) qua Qt Quick 3D.

### 🎯 2. Ba trụ cột tính năng chính
1. **Trợ Lý Hệ Thống (System Assistant):**
   - Hỗ trợ thực thi các câu lệnh đặc quyền `sudo` (có cơ chế xác thực và bảo vệ Human-in-the-Loop an toàn).
   - Tự động theo dõi, đánh giá, phân tích tình trạng sức khỏe phần cứng/phần mềm để đề xuất cập nhật, nâng cấp và tinh chỉnh tối ưu hệ thống NixOS.
2. **Trợ Lý Cá Nhân & Sức Khỏe (Personal & Health Assistant):**
   - **Bảo vệ sức khỏe theo chu kỳ (tích hợp cơ chế tương tự EyeLeo):** Nhắc nhở chớp mắt, nghỉ ngơi định kỳ, nhắc uống nước, bảo vệ thị lực và cột sống.
   - **Quản lý công việc & thời gian:** Báo thức, nhắc việc, đồng bộ lịch trình cá nhân, tích hợp dữ liệu WakaTime để thống kê hiệu suất lập trình.
3. **Trợ Lý Doanh Nghiệp & Tự Động Hóa Tác Vụ (Enterprise & Task Automation):**
   - Xây dựng bảng trình diễn (Dashboards/Presentations) đa phương tiện (văn bản, biểu đồ, hình ảnh, video).
   - Kết nối mở rộng ứng dụng (tương tự OpenClaw/MCP) để tóm tắt tài liệu, thống kê dữ liệu, soạn thảo email, tự động lập kế hoạch và thực thi chuỗi nhiệm vụ theo kịch bản có sẵn hoặc do AI tự khởi tạo.

---

## 🌟 Tính Năng Nổi Bật (Key Features)

- 🔒 **100% Air-gapped & Bảo mật tuyệt đối:** Toàn bộ dữ liệu hội thoại, tài liệu cá nhân, vector embeddings và tiến trình suy luận AI diễn ra nội bộ trên máy khách; không gửi bất kỳ telemetry nào ra ngoài internet.
- ⚡ **Zero Web Overhead (Native C++20 / Qt6):** Loại bỏ hoàn toàn Electron/Node.js/WebKitGTK nặng nề. Giao diện Desktop Pet / Mascot trong suốt tăng tốc phần cứng bằng Wayland Scene Graph mượt mà ở 60fps.
- 🔍 **Hybrid RAG Engine (FTS5 + `sqlite-vec`):** Tìm kiếm tri thức đa phương thức kết hợp từ khóa BM25 và ngữ nghĩa vector Cosine qua thuật toán Reciprocal Rank Fusion (RRF).
- 🧠 **Dynamic MoE Router (<30ms):** Tự động phân loại ý định (Text, Code, Vision) và hoán đổi mô hình động (Hot-Swap) tối ưu VRAM (<6GB) cho máy tính cá nhân.
- 🤖 **Actionable Agent & Safety Guard:** Vòng lặp ReAct (Reasoning + Acting) thực thi tác vụ tệp và lệnh Linux tự động qua `QProcess`, có cơ chế phê duyệt Human-in-the-Loop đối với các thao tác nhạy cảm.
- 🔄 **Self-Evolving Hub:** Tự động chưng cất tri thức từ dữ liệu tương tác thành công để tinh chỉnh LoRA cục bộ (`llama-finetune`) và lượng hóa thành phiên bản GGUF riêng biệt.

---

## 🏗️ Kiến Trúc Hệ Thống (Clean Architecture & Atomic Granularity)

Dự án áp dụng chặt chẽ 4 tầng Clean Architecture, tuân thủ nguyên tắc **phân rã cấu trúc hạt nhỏ nhất (Atomic Granularity)** nhằm giúp việc tra cứu trực quan và tối ưu hóa tối đa chi phí AI Token trong quá trình phát triển:

```text
troly/
├── src/
│   ├── domain/             # (Core) Pure C++20 Entities & Data Models phân rã vi mô (Zero dependency)
│   ├── usecases/           # (Business) Pure Virtual Interfaces / Skeleton Headers (*.hpp siêu nhẹ ~50 tokens)
│   ├── infrastructure/     # (Adapters) Module hóa riêng biệt: SQLite WAL, sqlite-vec, llama.cpp, Action Dispatcher
│   └── presentation/       # (UI) Qt6 ViewModels (QObject) & QML Scene Graph phân rã vi mô từng Component (/ui)
├── assets/                 # Tài nguyên hình ảnh, vector SVG thú cưng & âm thanh (/pet)
├── plan/                   # Hệ thống quản trị Agile Scrum Markdown UI/UX (phân tách sprint/backlog/daily)
├── docs/                   # Trung tâm tài liệu kỹ thuật (Kiến trúc, Git Workflow, Antigravity Setup)
├── .agents/                # Antigravity IDE Skills (Dynamic On-Demand Injection)
└── tests/                  # Bộ kiểm thử Unit Test (CTest / GTest) phân tách theo từng usecase/domain
```

---

## 🛠️ Yêu Cầu Hệ Thống & Tech Stack

- **Hệ điều hành:** NixOS (hoặc Linux hỗ trợ Wayland / X11).
- **Trình biên dịch & Công cụ:** GCC 13+ hoặc Clang 16+, CMake 3.25+, Ninja.
- **Thư viện chính:**
  - **Qt 6.7+** (`qtbase`, `qtdeclarative`, `qtquickcontrols2`).
  - **SQLite 3.45+** (chế độ WAL, FTS5).
  - **sqlite-vec** (`libvec0` vector search extension).
  - **llama.cpp** (C++ API nhúng tĩnh).
- **Môi trường phát triển:** [devenv.sh](https://devenv.sh) + [direnv](https://direnv.net).

---

## ⚡ Hướng Dẫn Cài Đặt & Khởi Chạy

### 1. Kích hoạt môi trường NixOS DevEnv

```bash
cd /etc/nixos/pkgs/troly

# Cho phép direnv tự động nạp môi trường
direnv allow

# Hoặc kích hoạt dev shell thủ công
devenv shell
```

### 2. Biên dịch dự án

```bash
# Cấu hình CMake với Ninja
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Debug
```

### 3. Biên dịch song song & Chạy Thử Giao Diện Preview

```bash
cmake --build build -j$(nproc)
```

> 🎯 **Quy chuẩn sau mỗi lần build:** Luôn thực hiện chạy thử ứng dụng để kiểm tra giao diện, độ trong suốt Wayland và cử động mascot cún cưng:

- **Chạy thực thi bản build C++:**
  ```bash
  ./build/troly
  ```
- **Chạy Live Preview QML tức thì (kiểm tra layout, icon, animation):**
  ```bash
  qml6 src/presentation/ui/main.qml
  ```

### 4. Đóng gói Nix Package & Kiểm thử Hệ Thống (`bam switch`)

Dự án `troly` là một **package con** của cấu hình NixOS bằng Flake tại `/etc/nixos/` (tương tự `/etc/nixos/pkgs/assistant/` và `/etc/nixos/pkgs/bam/`).

- **Đóng gói độc lập (Derivation cục bộ):**
  ```bash
  nix-build -E 'with import <nixpkgs> {}; callPackage ./default.nix {}'
  ```
- **Đóng gói qua Flake của dự án lớn (`/etc/nixos`):**
  ```bash
  cd /etc/nixos
  nix build .#troly # hoặc nix build . để build toplevel toàn hệ thống
  ```
- **Kiểm thử cập nhật hệ thống với lệnh `bam switch`:**
  Lệnh `bam switch` (thuộc package `/etc/nixos/pkgs/bam/`) là công cụ CLI quản trị hệ điều hành BamOS/NixOS:
  ```bash
  bam dry        # Kiểm tra trước thay đổi (dry-build)
  bam switch     # Rebuild và switch hệ thống (tự động gắn tag BamOS-YY.MM.DD-HH:MM)
  ```

---

## 🤝 Hệ Sinh Thái Multi-Agent (AI Software Factory)

Dự án được đồng phát triển bởi lập trình viên và 4 AI Agent chuyên biệt tích hợp sâu trên **Google Antigravity IDE**:

| Vai trò | Agent Handle | Nhiệm vụ cốt lõi |
| :--- | :--- | :--- |
| **Project Director** | `@PlanAgent` | Quản trị cây thư mục [plan/](file:///etc/nixos/pkgs/troly/plan), lập kế hoạch Sprint, điều phối Review, Retro và Daily Standup. |
| **R&D Specialist** | `@RdAgent` | Nghiên cứu kiến trúc, POC giải pháp, đánh giá trade-off (VRAM, CPU, latency) trước khi code. |
| **Software Engineer** | `@DevOptAgent` | Hiện thực hóa mã nguồn C++20, quản lý RAII, viết test, commit chuẩn Git, đóng gói Nix derivation và kiểm thử toàn hệ thống với `bam switch`. |
| **Lead 3D & Animation Director** | `@AnimAgent` | Chỉ đạo mỹ thuật nhân vật, chuyển động hoạt hình 12 nguyên tắc Disney, State Machine Mascot FSM, tối ưu Scene Graph 60fps và pipeline 3D Realtime. |

### 🌅 Nghi Thức Khởi Động Mỗi Ngày (Daily Kickoff)
Mỗi ngày khi bắt đầu làm việc, bạn chỉ cần ra một câu lệnh duy nhất:
```text
@PlanAgent và @DevOptAgent kiểm tra kế hoạch và thực hiện công việc hôm nay.
```
Hệ thống sẽ tự động quét [plan/sprints/sprint-01/PLAN.md](file:///etc/nixos/pkgs/troly/plan/sprints/sprint-01/PLAN.md), rà soát nhật ký hôm trước tại [plan/scrum/DAILY_SCRUM.md](file:///etc/nixos/pkgs/troly/plan/scrum/DAILY_SCRUM.md), xuất báo cáo buổi sáng và đề xuất phương án kỹ thuật triển khai ngay lập tức.

---

## 📚 Hệ Thống Tài Liệu Kỹ Thuật (`/docs/`)

- 🏗️ **Kiến trúc hệ thống chi tiết:** [docs/ARCHITECTURE.md](file:///etc/nixos/pkgs/troly/docs/ARCHITECTURE.md) *(SAD, ERD, DDL, DFD, ReAct, FSM, MoE Router)*
- 🌿 **Quy chuẩn Git & Versioning:** [docs/GIT_WORKFLOW.md](file:///etc/nixos/pkgs/troly/docs/GIT_WORKFLOW.md) *(vAA.BB.CC, Branching, Commit Why-What-Test, DoD)*
- ⚙️ **Thiết lập Antigravity IDE & Tối ưu Token:** [docs/ANTIGRAVITY_SETUP.md](file:///etc/nixos/pkgs/troly/docs/ANTIGRAVITY_SETUP.md) *(Rules vs Skills, Context Injection, Atomic Granularity)*
- 🗂️ **Chỉ mục tài liệu tổng thể:** [docs/README.md](file:///etc/nixos/pkgs/troly/docs/README.md)

---

## 📋 Quản Lý Dự Án (Agile Scrum Artifacts - `/plan/`)

- 🗺️ **Bản đồ kế hoạch:** [plan/README.md](file:///etc/nixos/pkgs/troly/plan/README.md)
- 📌 **Product Backlog (F1 - F7):** [plan/backlog/BACKLOG.md](file:///etc/nixos/pkgs/troly/plan/backlog/BACKLOG.md)
- 🏃 **Sprint 01 Hiện Tại:** [plan/sprints/sprint-01/PLAN.md](file:///etc/nixos/pkgs/troly/plan/sprints/sprint-01/PLAN.md)
- 📝 **Nhật ký Daily Standup:** [plan/scrum/DAILY_SCRUM.md](file:///etc/nixos/pkgs/troly/plan/scrum/DAILY_SCRUM.md)

---

## 📄 Bản Quyền (License)

Dự án được phát hành theo giấy phép **MIT License**. Bản quyền thuộc về [BamOS Project](https://bamos.info).
