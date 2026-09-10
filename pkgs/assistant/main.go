package main

import (
	"fmt"
	"os"
)

func main() {
	fmt.Println("==================================================")
	fmt.Println("🐶 BamOS Mascot AI Assistant (Web Tech + Go Core)")
	fmt.Println("   - SLM Inference Engine")
	fmt.Println("   - Embedded RAG (chromem-go)")
	fmt.Println("   - Transparent Desktop Pet Interface")
	fmt.Println("==================================================")

	cfg := loadConfig()
	fmt.Printf("[BamAI] Khởi tạo cấu hình: Provider=%s, RAG=%t, LlamaHost=%s\n", cfg.Provider, cfg.EnableRAG, cfg.LlamaHost)

	ragMgr := NewRAGManager(cfg.RAGDBPath, cfg.LlamaHost)
	fsTool := NewFSTool()
	userMem := NewUserMemory()
	aiService := NewAIService(cfg, ragMgr, fsTool, userMem)

	// Khởi động giao diện người dùng
	if os.Getenv("DISPLAY") == "" && os.Getenv("WAYLAND_DISPLAY") == "" {
		fmt.Println("[BamAI Lỗi] Không tìm thấy DISPLAY hoặc WAYLAND_DISPLAY.")
		os.Exit(1)
	}

	StartUI(aiService)
}
