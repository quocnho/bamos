package domain

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
	ThemeStyle        string `json:"theme_style"`         // "default", "cyberpunk", "warm", "nord", "oled"
	NightLightSync    bool   `json:"night_light_sync"`    // Đồng bộ theo chế độ dịu mắt GNOME Wayland
	WakaTrackerActive bool   `json:"wakatracker_active"`  // Theo dõi thời gian làm việc & năng suất
	SystemWatchActive bool   `json:"system_watch_active"` // Tự động quét log & cảnh báo ứng dụng ngầm
}

const (
	DefaultLlamaHost = "http://127.0.0.1:9090"
	DefaultModelDir  = "/var/lib/bamos/models"
	DefaultModelPath = "/var/lib/bamos/models/qwen2.5-1.5b-instruct-q4_k_m.gguf"
	DefaultRAGDBPath = "/var/lib/bamos/rag/knowledge.db"
)

func DefaultConfig() Config {
	return Config{
		Provider:          "local",
		EnableRAG:         true,
		LlamaHost:         DefaultLlamaHost,
		ModelDir:          DefaultModelDir,
		ModelPath:         DefaultModelPath,
		RAGDBPath:         DefaultRAGDBPath,
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

// Normalize điền các giá trị mặc định còn thiếu.
func (c *Config) Normalize() {
	if c.Provider == "" {
		c.Provider = "local"
	}
	if c.LlamaHost == "" {
		c.LlamaHost = DefaultLlamaHost
	}
	if c.ModelDir == "" {
		c.ModelDir = DefaultModelDir
	}
	if c.ModelPath == "" {
		c.ModelPath = DefaultModelPath
	}
	if c.RAGDBPath == "" {
		c.RAGDBPath = DefaultRAGDBPath
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
