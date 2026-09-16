package fs

import (
	"encoding/json"
	"os"
	"path/filepath"

	"troly/backend/internal/domain"
)

type ConfigStore struct {
	configDir string
}

func NewConfigStore() *ConfigStore {
	configDir := os.Getenv("XDG_CONFIG_HOME")
	if configDir == "" {
		home, _ := os.UserHomeDir()
		configDir = filepath.Join(home, ".config")
	}
	dir := filepath.Join(configDir, "bamos")
	_ = os.MkdirAll(dir, 0o755)
	return &ConfigStore{configDir: dir}
}

func (s *ConfigStore) GetConfigPath() string {
	return filepath.Join(s.configDir, "assistant_config.json")
}

func (s *ConfigStore) LoadConfig() domain.Config {
	cfg := domain.DefaultConfig()
	if data, err := os.ReadFile(s.GetConfigPath()); err == nil {
		_ = json.Unmarshal(data, &cfg)
	}
	cfg.Normalize()
	return cfg
}

func (s *ConfigStore) SaveConfig(cfg domain.Config) error {
	cfg.Normalize()
	data, err := json.MarshalIndent(cfg, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(s.GetConfigPath(), data, 0o644)
}

func GetWindowStatePath() string {
	if dir := os.Getenv("BAMAI_STATE_DIR"); dir != "" {
		_ = os.MkdirAll(dir, 0o755)
		return filepath.Join(dir, "window_state.json")
	}
	sysDir := "/var/lib/bamos/state"
	if err := os.MkdirAll(sysDir, 0o755); err == nil {
		return filepath.Join(sysDir, "window_state.json")
	}
	home, _ := os.UserHomeDir()
	legacyDir := filepath.Join(home, ".config", "bamos")
	_ = os.MkdirAll(legacyDir, 0o755)
	return filepath.Join(legacyDir, "window_state.json")
}
