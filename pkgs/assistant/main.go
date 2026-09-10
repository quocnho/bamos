package main

import (
	"fmt"
	"net"
	"net/http"
	"net/url"
	"os"
	"strings"
	"time"
)

// preferX11Backend chọn GDK_BACKEND=x11 khi có XWayland.
//
// Lý do: trên GNOME Wayland thuần, các API quản lý cửa sổ mà ứng dụng cần đều
// là no-op (gtk_window_set_keep_above, gtk_window_move). Chạy qua XWayland
// (X11) giúp các tính năng "ghim trên cùng", "nhớ vị trí" và "đưa cửa sổ lên
// trên khi nhắc nghỉ" hoạt động thật.
//
// Có thể ghi đè bằng biến môi trường BAMAI_GDK_BACKEND (x11 | wayland).
func preferX11Backend() {
	if override := os.Getenv("BAMAI_GDK_BACKEND"); override != "" {
		_ = os.Setenv("GDK_BACKEND", override)
		fmt.Printf("[BamAI GUI] GDK_BACKEND=%s (theo BAMAI_GDK_BACKEND)\n", override)
		return
	}
	if current := os.Getenv("GDK_BACKEND"); current != "" {
		fmt.Printf("[BamAI GUI] GDK_BACKEND=%s (đã đặt sẵn)\n", current)
		return
	}
	// DISPLAY được đặt nghĩa là X(XWayland) sẵn sàng → ưu tiên x11.
	if os.Getenv("DISPLAY") != "" {
		_ = os.Setenv("GDK_BACKEND", "x11")
		fmt.Println("[BamAI GUI] GDK_BACKEND=x11 (XWayland) — bật ghim cửa sổ & nhớ vị trí")
		return
	}
	fmt.Println("[BamAI GUI] Không có DISPLAY — dùng backend mặc định của GTK (Wayland)")
}

// preferStableWebKitRendering tắt renderer DMA-BUF của WebKitGTK.
//
// Lý do: trên XWayland + GPU NVIDIA/hybrid, renderer DMA-BUF của WebKit hay cho
// ra cửa sổ ĐEN (nội dung không vẽ) cho tới khi người dùng click/chạm vào cửa sổ
// — đúng hiện tượng gặp khi BamAI tự khởi động lúc cold-boot. Tắt DMA-BUF để
// WebKit dùng đường vẽ dự phòng (ổn định) và vẽ frame đầu ngay.
//
// Có thể ghi đè bằng WEBKIT_DISABLE_DMABUF_RENDERER=0 nếu máy không gặp lỗi.
// PHẢI gọi TRƯỚC khi GTK/WebKit khởi tạo.
func preferStableWebKitRendering() {
	if os.Getenv("WEBKIT_DISABLE_DMABUF_RENDERER") == "" {
		_ = os.Setenv("WEBKIT_DISABLE_DMABUF_RENDERER", "1")
		fmt.Println("[BamAI GUI] WEBKIT_DISABLE_DMABUF_RENDERER=1 (tránh cửa sổ đen trên XWayland/NVIDIA)")
	}
}

// assistantPort là cổng HTTP nội bộ. Có thể đổi bằng BAMAI_PORT để chạy
// instance thử nghiệm song song mà không đụng tới ứng dụng đang chạy.
func assistantPort() string {
	if port := os.Getenv("BAMAI_PORT"); port != "" {
		return port
	}
	return "9195"
}

func assistantURL(path string) string {
	return fmt.Sprintf("http://127.0.0.1:%s%s", assistantPort(), path)
}

// debugEnabled bật nhật ký chẩn đoán khi đặt BAMAI_DEBUG=1.
func debugEnabled() bool {
	return os.Getenv("BAMAI_DEBUG") != ""
}

func main() {
	fmt.Println("==================================================")
	fmt.Println("🐶 BamOS Mascot AI Assistant (Web Tech + Go Core)")
	fmt.Println("   - SLM Inference Engine")
	fmt.Println("   - Embedded RAG (chromem-go)")
	fmt.Println("   - Transparent Desktop Pet Interface")
	fmt.Println("==================================================")

	preferX11Backend()
	preferStableWebKitRendering()

	// --settings <panel>: mở bảng thiết lập (rag|llm|eyeleo|about) — dùng bởi menu
	// sổ xuống trên thanh trên cùng của GNOME Shell.
	//  • BamAI đang chạy  -> nhờ instance hiện tại mở bảng.
	//  • BamAI chưa chạy  -> khởi động kèm `#panel=<tên>` để giao diện tự mở bảng.
	startupPanel := ""
	for i := 1; i < len(os.Args); i++ {
		if os.Args[i] != "--settings" || i+1 >= len(os.Args) {
			continue
		}
		panel := os.Args[i+1]
		if isAssistantAlreadyRunning() {
			endpoint := assistantURL("/api/open-settings?panel=" + url.QueryEscape(panel))
			if _, err := http.Get(endpoint); err != nil {
				fmt.Printf("[BamAI] Không mở được bảng thiết lập %q: %v\n", panel, err)
			}
			return
		}
		startupPanel = panel
		break
	}

	// Lệnh điều khiển nhanh từ bên ngoài (GNOME Shell indicator, script...).
	// --hide: ẩn cửa sổ nhưng vẫn chạy nền; --quit: dừng AI/RAG và thoát.
	for _, arg := range os.Args[1:] {
		if arg != "--hide" && arg != "--quit" {
			continue
		}
		if !isAssistantAlreadyRunning() {
			fmt.Println("[BamAI] Không có BamAI nào đang chạy.")
			return
		}
		endpoint := "/api/hide"
		if arg == "--quit" {
			endpoint = "/api/quit"
		}
		if _, err := http.Get(assistantURL(endpoint)); err != nil {
			fmt.Printf("[BamAI] Không gửi được lệnh %s: %v\n", arg, err)
		}
		return
	}

	cfg := loadConfig()
	fmt.Printf("[BamAI] Khởi tạo cấu hình: Provider=%s, RAG=%t, LlamaHost=%s\n", cfg.Provider, cfg.EnableRAG, cfg.LlamaHost)

	ragMgr := NewRAGManager(cfg.RAGDBPath, cfg.LlamaHost)
	fsTool := NewFSTool()
	userMem := NewUserMemory()

	// Kiểm tra nếu được gọi kèm tham số đường dẫn (Ví dụ từ Nautilus / CLI)
	var targetDir string
	for i := 1; i < len(os.Args); i++ {
		arg := os.Args[i]
		if arg == "--context-dir" && i+1 < len(os.Args) {
			targetDir = os.Args[i+1]
			break
		} else if !strings.HasPrefix(arg, "-") {
			// Kiểm tra nếu là thư mục hợp lệ
			if info, err := os.Stat(arg); err == nil && info.IsDir() {
				targetDir = arg
				break
			}
		}
	}

	// Nếu ứng dụng đang chạy (cổng nội bộ đã mở), gửi tín hiệu bối cảnh thư mục sang phiên đang chạy
	if isAssistantAlreadyRunning() {
		if targetDir != "" {
			escaped := url.QueryEscape(targetDir)
			_, _ = http.Get(assistantURL("/api/context-dir?path=" + escaped))
			fmt.Printf("[BamAI] Đã gửi Cục Xương bối cảnh `%s` sang BamAI đang chạy!\n", targetDir)
		} else {
			_, _ = http.Get(assistantURL("/api/show"))
			fmt.Println("[BamAI] Đã hiển thị BamAI!")
		}
		return
	}

	if targetDir != "" {
		userMem.SetActiveDirectory(targetDir)
	}

	aiService := NewAIService(cfg, ragMgr, fsTool, userMem)

	// Khởi động giao diện người dùng
	if os.Getenv("DISPLAY") == "" && os.Getenv("WAYLAND_DISPLAY") == "" {
		fmt.Println("[BamAI Lỗi] Không tìm thấy DISPLAY hoặc WAYLAND_DISPLAY.")
		os.Exit(1)
	}

	StartUI(aiService, startupPanel)
}

func isAssistantAlreadyRunning() bool {
	conn, err := net.DialTimeout("tcp", "127.0.0.1:"+assistantPort(), 300*time.Millisecond)
	if err == nil {
		conn.Close()
		return true
	}
	return false
}
