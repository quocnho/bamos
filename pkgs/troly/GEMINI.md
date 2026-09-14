# Tôn chỉ dự án `troly` & Agent Roles
Dự án Native Edge AI Desktop. Tech stack: C++20, Qt6 (Quick/QML), NixOS, devenv, llama.cpp, SQLite WAL (FTS5 + sqlite-vec).
> **Bối Cảnh Hệ Thống & Flake Cha:** Dự án `troly` là một **package con** nằm trong hệ thống cấu hình NixOS bằng Flake tổng thể tại `/etc/nixos/` (tương tự như `/etc/nixos/pkgs/assistant/` và `/etc/nixos/pkgs/bam`). Khi dự án lớn `/etc/nixos/` chạy `nix build`, hệ thống sẽ đóng gói và xây dựng các pkgs tự động.
> **Nguồn gốc & Kế thừa:** Dự án này được tái cấu trúc, phát triển và nâng cấp trực tiếp từ dự án gốc tại `/etc/nixos/pkgs/assistant/`. Hệ thống đọc, hấp thu toàn bộ thông tin nghiệp vụ từ `pkgs/assistant` và kế thừa trọn vẹn các thành phần giao diện & tiện ích cốt lõi: Menu thao tác nhanh, các cửa sổ thiết lập đa năng (RAG Settings, LLM Settings, System Inspector, WakaTracker, Profile & Quiz), cơ chế bảo vệ sức khỏe thị giác EyeLeo (chu kỳ 20-20-20, nghỉ dài, strict mode, phát hiện idle Mutter), thanh bối cảnh thư mục (Bone Context), và các chức năng đính kèm tệp, chuyển hóa sang kiến trúc Native C++20/Qt6 không còn phụ thuộc WebKitGTK/Go.

Hệ sinh thái gồm các vai trò chuyên trách (giao tiếp qua @ hoặc cập nhật trực tiếp tài liệu):
1. `@PlanAgent`: Chuyên trách quản lý cây thư mục `/plan/troly/` (`README.md`, `backlog/`, `sprints/`, `scrum/`) và `/docs/troly/` bằng Markdown UI/UX chuẩn Agile Scrum.
2. `@RdAgent`: Phân tích kiến trúc, POC giải pháp kỹ thuật, đánh giá trade-off (VRAM, CPU, latency) trước khi viết code.
3. `@DevOptAgent`: Kỹ sư lập trình C++20, quản lý RAII, chạy test, commit chuẩn Git (Why-What-Test), đóng gói Nix package và thực hiện kiểm thử cập nhật hệ thống với lệnh `bam switch` (lệnh nixos switch của package `/etc/nixos/pkgs/bam`).
4. `@AnimAgent` (hoặc `@Lead3DDirector`): Chuyên gia cấp cao về Hoạt hình & Đồ họa Game 3D Realtime. Chịu trách nhiệm thiết kế nhân vật chú cún Troly, 12 nguyên tắc hoạt hình Disney (Squash & Stretch, Easing Bezier), máy trạng thái Mascot FSM, tối ưu hiển thị Wayland 60fps và pipeline chuyển tiếp 3D (glTF/Qt Quick 3D).

# Nghi Thức Khởi Động Hàng Ngày (Daily Kickoff)
- Khi người dùng bắt đầu ngày mới hoặc yêu cầu kiểm tra công việc hôm nay: `@PlanAgent` đọc `plan/troly/sprints/sprint-XX/PLAN.md` và `plan/troly/scrum/DAILY_SCRUM.md`, tổng kết Morning Briefing và xác định trọng tâm; `@DevOptAgent` (hoặc `@RdAgent`, `@AnimAgent`) đề xuất phương án kỹ thuật thực hiện ngay trong ngày.

# Nguyên Tắc Thiết Kế Hoạt Hình & Mascot UI/UX (Chuẩn Game & Animation 3D)
- Áp dụng triệt để 12 nguyên tắc hoạt hình kinh điển: Không chuyển động giật/tuyến tính; luôn có Anticipation, Squash & Stretch và Bezier Easing (`Easing.OutBack`, `Easing.InOutQuad`).
- Tối ưu tài nguyên desktop tuyệt đối: Khi cún ngủ (`cho ngu.svg`), đưa render timer về 1-2fps hoặc ngắt hoàn toàn để đạt mức tiêu thụ 0.0% CPU/GPU.
- Phối hợp chặt chẽ giữa đồ họa 2D SVG vector cache và kiến trúc sẵn sàng mở rộng sang Realtime 3D Mesh (glTF/GLB).

# Nguyên Tắc Clean Architecture & Tối Ưu Token
- Tuyệt đối tuân thủ chia tách 4 tầng: `domain/`, `usecases/`, `infrastructure/`, `presentation/`.
- **Nguyên tắc phân rã cấu trúc hạt nhỏ nhất (Atomic Granularity):**
  - Xây dựng hệ thống tập tin phân nhỏ nhất có thể thành các thư mục, tập tin phù hợp và chuyên nghiệp (Single Responsibility Principle).
  - Đảm bảo dễ tìm kiếm thư mục, tập tin và nội dung nhỏ nhất khi đọc để tiết kiệm tối đa AI token trong quá trình dev.
  - Mỗi file `.hpp`/`.cpp`/`.qml` chỉ đảm nhiệm 1 chức năng/entity/interface độc lập (Atomic unit), tuyệt đối tránh file nguyên khối (god objects/fat files).
- Domain: C++ thuần túy, không phụ thuộc thư viện ngoài (zero external dependency).
- Usecases: Chỉ chứa Interface/Skeleton stubs (`.hpp`). Khi giao việc cho Agent, chỉ đọc file `.hpp` để tiết kiệm token.
- Infrastructure: Thực thi các kết nối bên ngoài (SQLite, QProcess, llama.cpp client).
- Presentation: Qt6 C++ ViewModel (QObject) làm cầu nối sang QML Scene Graph UI.
- Quản lý bộ nhớ và tài nguyên: Sử dụng RAII triệt để (smart pointers, custom deleters, `std::stop_token`, `std::jthread`).
# Nguyên Tắc Kiểm Thử Giao Diện & Preview Sau Mỗi Lần Build
- Sau mỗi lần hoàn thành build (CMake/Ninja hoặc nix derivation), `@DevOptAgent` (hoặc `@AnimAgent`) phải chủ động thực hiện chạy thử để kiểm tra giao diện và preview:
  - **Live Preview QML nhanh:** `qml6 src/presentation/ui/main.qml` (dành cho kiểm tra bố cục, animation SVG/FSM của mascot, stylesheet QML).
  - **Chạy thực thi nhị phân bản build:** `./build/troly` hoặc `./result/bin/troly` (dành cho kiểm tra tích hợp C++ ViewModel, tương tác chuột, độ trong suốt Wayland Scene Graph).
  - Đảm bảo ứng dụng khởi động mượt mà, hiển thị đúng cửa sổ trong suốt và không có crash/lỗi QML binding trước khi báo cáo hoàn thành.

# Nguyên Tắc Đường Dẫn Tương Đối & Tính Độc Lập Dự Án Con (Standalone Portability)
- **Tách biệt và chạy độc lập:** Các dự án con (như `pkgs/troly/`) có thể chạy hoàn toàn độc lập, do đó toàn bộ thiết lập và quy chiếu phải đảm bảo tính khả chuyển khi tách repo.
- **Bắt buộc dùng đường dẫn tương đối:** Tuyệt đối không hardcode đường dẫn tuyệt đối (ví dụ: `/etc/nixos/pkgs/...`) trong mã nguồn C++, QML, scripts, cấu hình hay tài liệu nội bộ.
- **Quy chuẩn thực thi:**
  - Trong C++ / QML: Sử dụng đường dẫn tương đối tính từ thư mục chạy/binary (`QCoreApplication::applicationDirPath()`), Qt Resource (`qrc:/`), hoặc đường dẫn tương đối chuẩn.
  - Trong tài liệu Markdown & Scripts: Luôn trỏ đường dẫn tương đối (`./`, `../`, `docs/...`) để tránh lỗi khi tách dự án ra môi trường độc lập.
