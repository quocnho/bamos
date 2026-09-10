package main

import (
	"encoding/json"
	"os"
	"path/filepath"
)

type Config struct {
	Provider    string `json:"provider"`
	DeepSeekKey string `json:"deepseek_key"`
	OpenAIKey   string `json:"openai_key"`
	GeminiKey   string `json:"gemini_key"`
	EnableRAG   bool   `json:"enable_rag"`
	LlamaHost   string `json:"llama_host"`
	RAGDBPath   string `json:"rag_db_path"`
}

func defaultConfig() Config {
	return Config{
		Provider:  "local",
		EnableRAG: true,
		LlamaHost: "http://127.0.0.1:9090",
		RAGDBPath: "/var/lib/bamos/rag/knowledge.db",
	}
}

func getConfigPath() string {
	configDir := os.Getenv("XDG_CONFIG_HOME")
	if configDir == "" {
		home, _ := os.UserHomeDir()
		configDir = filepath.Join(home, ".config")
	}
	dir := filepath.Join(configDir, "bamos")
	_ = os.MkdirAll(dir, 0755)
	return filepath.Join(dir, "assistant_config.json")
}

func loadConfig() Config {
	cfg := defaultConfig()
	path := getConfigPath()
	data, err := os.ReadFile(path)
	if err == nil {
		_ = json.Unmarshal(data, &cfg)
	}
	if cfg.LlamaHost == "" {
		cfg.LlamaHost = "http://127.0.0.1:9090"
	}
	if cfg.RAGDBPath == "" {
		cfg.RAGDBPath = "/var/lib/bamos/rag/knowledge.db"
	}
	return cfg
}

func saveConfig(cfg Config) {
	path := getConfigPath()
	data, err := json.MarshalIndent(cfg, "", "  ")
	if err == nil {
		_ = os.WriteFile(path, data, 0644)
	}
}
