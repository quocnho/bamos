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
		return
	}
	if os.Getenv("GDK_BACKEND") != "" {
		return // người dùng đã tự chọn backend
	}
	// DISPLAY được đặt nghĩa là X(XWayland) sẵn sàng → ưu tiên x11.
	if os.Getenv("DISPLAY") != "" {
		_ = os.Setenv("GDK_BACKEND", "x11")
	}
}

func main() {
	fmt.Println("==================================================")
	fmt.Println("🐶 BamOS Mascot AI Assistant (Web Tech + Go Core)")
	fmt.Println("   - SLM Inference Engine")
	fmt.Println("   - Embedded RAG (chromem-go)")
	fmt.Println("   - Transparent Desktop Pet Interface")
	fmt.Println("==================================================")

	preferX11Backend()

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

	// Nếu ứng dụng đang chạy (cổng 9195 đã mở), gửi tín hiệu bối cảnh thư mục sang phiên đang chạy
	if isAssistantAlreadyRunning() {
		if targetDir != "" {
			escaped := url.QueryEscape(targetDir)
			_, _ = http.Get(fmt.Sprintf("http://127.0.0.1:9195/api/context-dir?path=%s", escaped))
			fmt.Printf("[BamAI] Đã gửi Cục Xương bối cảnh `%s` sang BamAI đang chạy!\n", targetDir)
		} else {
			_, _ = http.Get("http://127.0.0.1:9195/api/show")
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

	StartUI(aiService)
}

func isAssistantAlreadyRunning() bool {
	conn, err := net.DialTimeout("tcp", "127.0.0.1:9195", 300*time.Millisecond)
	if err == nil {
		conn.Close()
		return true
	}
	return false
}
