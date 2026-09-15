package main

import (
	"encoding/json"
	"os"
	"path/filepath"
	"regexp"
	"strings"
)

// Config là cấu hình runtime của BamAI, được lưu tại
// ~/.config/bamos/assistant_config.json và có thể chỉnh sửa từ bảng
// thiết lập LLM/RAG trên giao diện.
type Config struct {
	// Nhà cung cấp LLM: local | deepseek | openai | gemini
	Provider string `json:"provider"`

	// Khóa API cho các nhà cung cấp đám mây
	DeepSeekKey string `json:"deepseek_key"`
	OpenAIKey   string `json:"openai_key"`
	GeminiKey   string `json:"gemini_key"`

	// llama-server cục bộ
	LlamaHost   string  `json:"llama_host"`
	ModelDir    string  `json:"model_dir"`
	ModelPath   string  `json:"model_path"`
	ContextSize int     `json:"context_size"`
	GpuLayers   int     `json:"gpu_layers"`
	Temperature float64 `json:"temperature"`

	// RAG (tri thức nội bộ - SQLite FTS5 + sqlite-vec)
	EnableRAG      bool    `json:"enable_rag"`
	RAGDBPath      string  `json:"rag_db_path"`
	RAGTopK        int     `json:"rag_top_k"`
	RAGHybridAlpha float64 `json:"rag_hybrid_alpha"` // Trọng số: 0.0 (FTS thuần) -> 1.0 (Vector thuần), mặc định 0.65

	// Giao diện, Cá nhân hoá & Thói quen
	Addressing        string `json:"addressing"`
	AlwaysOnTop       bool   `json:"always_on_top"`
	ThemeStyle        string `json:"theme_style"`        // "default", "cyberpunk", "warm", "nord", "oled"
	NightLightSync    bool   `json:"night_light_sync"`   // Đồng bộ theo chế độ dịu mắt GNOME Wayland
	WakaTrackerActive bool   `json:"wakatracker_active"` // Theo dõi thời gian làm việc & năng suất
	SystemWatchActive bool   `json:"system_watch_active"` // Tự động quét log & cảnh báo ứng dụng ngầm

	// Thiết lập nhúng Web Widget & Danh sách trắng Domain
	Widget WidgetConfig `json:"widget"`
}

type WhitelistItem struct {
	ID        string `json:"id"`
	Domain    string `json:"domain"`    // Ví dụ: "http://localhost:3000", "https://myblog.com", "*.mycompany.local"
	Note      string `json:"note"`      // Ghi chú dự án
	Enabled   bool   `json:"enabled"`   // Bật/tắt kích hoạt
	CreatedAt string `json:"created_at"`
}

type WidgetConfig struct {
	Port             string          `json:"port"`               // Mặc định: "9195"
	Host             string          `json:"host"`               // "127.0.0.1" hoặc "0.0.0.0"
	Position         string          `json:"position"`           // "bottom-right" | "bottom-left"
	PrimaryColor     string          `json:"primary_color"`      // Hex hoặc CSS Gradient
	Title            string          `json:"title"`              // Tiêu đề bot
	WelcomeMsg       string          `json:"welcome_msg"`        // Lời chào mở đầu
	DefaultRAG       bool            `json:"default_rag"`        // Bật/tắt RAG mặc định
	SoundEnabled     bool            `json:"sound_enabled"`      // Chuông âm thanh
	EnforceWhitelist bool            `json:"enforce_whitelist"`  // Bắt buộc kiểm tra Whitelist (true/false)
	Whitelist        []WhitelistItem `json:"whitelist"`          // Danh sách các domain được cấp phép
}

// IsOriginAllowed kiểm tra xem Origin từ request có được phép truy cập theo Whitelist hay không.
func (w *WidgetConfig) IsOriginAllowed(origin string) bool {
	if !w.EnforceWhitelist || len(w.Whitelist) == 0 {
		return true // Nếu không bắt buộc hoặc danh sách rỗng thì cho phép tất cả
	}
	if origin == "" {
		return true // Request không có origin (ví dụ gọi cùng domain hoặc curl)
	}

	trimmedOrigin := strings.TrimSpace(strings.ToLower(origin))

	for _, item := range w.Whitelist {
		if !item.Enabled {
			continue
		}
		target := strings.TrimSpace(strings.ToLower(item.Domain))
		if target == "*" || target == trimmedOrigin {
			return true
		}

		// Xử lý wildcard dạng *.domain.com hoặc *domain.com
		if strings.HasPrefix(target, "*.") {
			rootDomain := strings.TrimPrefix(target, "*.")
			// Kiểm tra domain gốc hoặc subdomain
			if strings.HasSuffix(trimmedOrigin, "."+rootDomain) || strings.HasSuffix(trimmedOrigin, "://"+rootDomain) {
				return true
			}
		} else if strings.Contains(target, "*") {
			pattern := "^" + strings.ReplaceAll(regexp.QuoteMeta(target), "\\*", ".*") + "$"
			if matched, _ := regexp.MatchString(pattern, trimmedOrigin); matched {
				return true
			}
		}
	}
	return false
}

func defaultWidgetConfig() WidgetConfig {
	return WidgetConfig{
		Port:             "9195",
		Host:             "127.0.0.1",
		Position:         "bottom-right",
		PrimaryColor:     "linear-gradient(135deg, #FF9F43 0%, #EE5253 100%)",
		Title:            "BamOS Copilot",
		WelcomeMsg:       "Gâu gâu! Em là BamOS Mascot Copilot đây ạ 🐾. Em có thể giải đáp thắc mắc, tra cứu tài liệu hệ thống và hỗ trợ bạn trực tiếp ngay trên trang web này!",
		DefaultRAG:       true,
		SoundEnabled:     true,
		EnforceWhitelist: false,
		Whitelist: []WhitelistItem{
			{
				ID:        "wl-local-1",
				Domain:    "http://localhost:3000",
				Note:      "Môi trường phát triển Next.js / Vite cục bộ",
				Enabled:   true,
				CreatedAt: "2026-09-15",
			},
			{
				ID:        "wl-local-2",
				Domain:    "http://127.0.0.1:8080",
				Note:      "Trang thử nghiệm nội bộ",
				Enabled:   true,
				CreatedAt: "2026-09-15",
			},
		},
	}
}

const (
	defaultLlamaHost = "http://127.0.0.1:9090"
	defaultModelDir  = "/var/lib/bamos/models"
	defaultModelPath = "/var/lib/bamos/models/qwen2.5-1.5b-instruct-q4_k_m.gguf"
	defaultRAGDBPath = "/var/lib/bamos/rag/knowledge.db"
)

func defaultConfig() Config {
	return Config{
		Provider:          "local",
		EnableRAG:         true,
		LlamaHost:         defaultLlamaHost,
		ModelDir:          defaultModelDir,
		ModelPath:         defaultModelPath,
		RAGDBPath:         defaultRAGDBPath,
		RAGTopK:           4,
		RAGHybridAlpha:    0.65,
		Temperature:       0.7,
		ContextSize:       4096,
		GpuLayers:         99,
		Addressing:        "Chủ nhân",
		AlwaysOnTop:       true,
		ThemeStyle:        "default",
		NightLightSync:    true,
		WakaTrackerActive: true,
		SystemWatchActive: true,
		Widget:            defaultWidgetConfig(),
	}
}

// bamosConfigDir trả về thư mục ~/.config/bamos (tạo nếu chưa có).
func bamosConfigDir() string {
	configDir := os.Getenv("XDG_CONFIG_HOME")
	if configDir == "" {
		home, _ := os.UserHomeDir()
		configDir = filepath.Join(home, ".config")
	}
	dir := filepath.Join(configDir, "bamos")
	_ = os.MkdirAll(dir, 0o755)
	return dir
}

func getConfigPath() string {
	return filepath.Join(bamosConfigDir(), "assistant_config.json")
}

// getWindowStatePath trả về file lưu mốc neo cửa sổ/pet (góc dưới-phải).
//
// Ưu tiên thư mục TRẠNG THÁI HỆ THỐNG /var/lib/bamos/state (nằm NGOÀI $HOME):
// nhờ vậy việc dọn cache / xoá dữ liệu WebView / đổi profile KHÔNG làm mất vị
// trí người dùng đã kéo thả. Ghi đè bằng BAMAI_STATE_DIR khi chạy instance thử.
func getWindowStatePath() string {
	if dir := os.Getenv("BAMAI_STATE_DIR"); dir != "" {
		_ = os.MkdirAll(dir, 0o755)
		return filepath.Join(dir, "window_state.json")
	}
	sysDir := "/var/lib/bamos/state"
	if err := os.MkdirAll(sysDir, 0o755); err == nil {
		return filepath.Join(sysDir, "window_state.json")
	}
	return getLegacyWindowStatePath()
}

// getLegacyWindowStatePath là vị trí CŨ (~/.config/bamos) — chỉ dùng để ĐỌC
// nhằm di trú vị trí đã lưu từ các bản trước.
func getLegacyWindowStatePath() string {
	return filepath.Join(bamosConfigDir(), "window_state.json")
}

// normalize điền các giá trị mặc định còn thiếu sau khi đọc từ đĩa.
func (c *Config) normalize() {
	if c.Provider == "" {
		c.Provider = "local"
	}
	if c.LlamaHost == "" {
		c.LlamaHost = defaultLlamaHost
	}
	if c.ModelDir == "" {
		c.ModelDir = defaultModelDir
	}
	if c.ModelPath == "" {
		c.ModelPath = defaultModelPath
	}
	if c.RAGDBPath == "" {
		c.RAGDBPath = defaultRAGDBPath
	}
	if c.RAGTopK <= 0 {
		c.RAGTopK = 4
	}
	if c.RAGHybridAlpha <= 0 || c.RAGHybridAlpha > 1.0 {
		c.RAGHybridAlpha = 0.65
	}
	if c.ThemeStyle == "" {
		c.ThemeStyle = "default"
	}
	if c.Temperature < 0 {
		c.Temperature = 0.7
	}
	if c.Addressing == "" {
		c.Addressing = "Chủ nhân"
	}
	if c.ContextSize <= 0 {
		c.ContextSize = 4096
	}
	if c.GpuLayers < 0 {
		c.GpuLayers = 0
	}
	if c.Widget.Port == "" {
		c.Widget.Port = "9195"
	}
	if c.Widget.Host == "" {
		c.Widget.Host = "127.0.0.1"
	}
	if c.Widget.Position == "" {
		c.Widget.Position = "bottom-right"
	}
	if c.Widget.PrimaryColor == "" {
		c.Widget.PrimaryColor = "linear-gradient(135deg, #FF9F43 0%, #EE5253 100%)"
	}
	if c.Widget.Title == "" {
		c.Widget.Title = "BamOS Copilot"
	}
	if c.Widget.WelcomeMsg == "" {
		c.Widget.WelcomeMsg = "Gâu gâu! Em là BamOS Mascot Copilot đây ạ 🐾. Em có thể giải đáp thắc mắc, tra cứu tài liệu hệ thống và hỗ trợ bạn trực tiếp ngay trên trang web này!"
	}
}

func loadConfig() Config {
	cfg := defaultConfig()
	if data, err := os.ReadFile(getConfigPath()); err == nil {
		_ = json.Unmarshal(data, &cfg)
	}
	cfg.normalize()
	return cfg
}

func saveConfig(cfg Config) error {
	cfg.normalize()
	data, err := json.MarshalIndent(cfg, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(getConfigPath(), data, 0o644)
}
