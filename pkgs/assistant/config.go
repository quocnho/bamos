package main

import (
	"encoding/json"
	"os"
	"path/filepath"
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
