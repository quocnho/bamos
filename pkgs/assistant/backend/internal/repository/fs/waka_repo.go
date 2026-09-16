package fs

import (
	"encoding/json"
	"os"
	"path/filepath"
	"sync"

	"bamos-assistant/backend/internal/domain"
)

type WakaRepo struct {
	mu       sync.RWMutex
	filePath string
	data     domain.WakaData
}

func NewWakaRepo() *WakaRepo {
	home, _ := os.UserHomeDir()
	dir := filepath.Join(home, ".local", "share", "bamos")
	_ = os.MkdirAll(dir, 0755)
	file := filepath.Join(dir, "wakatracker.json")

	repo := &WakaRepo{
		filePath: file,
		data: domain.WakaData{
			DailyStats:    make(map[string]*domain.DayStat),
			ProjectStats:  make(map[string]int),
			CategoryStats: make(map[string]int),
			Reminders:     make([]domain.WakaReminder, 0),
		},
	}
	repo.load()
	return repo
}

func (r *WakaRepo) load() {
	r.mu.Lock()
	defer r.mu.Unlock()

	data, err := os.ReadFile(r.filePath)
	if err == nil {
		_ = json.Unmarshal(data, &r.data)
	}
	if r.data.DailyStats == nil {
		r.data.DailyStats = make(map[string]*domain.DayStat)
	}
	if r.data.ProjectStats == nil {
		r.data.ProjectStats = make(map[string]int)
	}
	if r.data.CategoryStats == nil {
		r.data.CategoryStats = make(map[string]int)
	}
	if r.data.Reminders == nil {
		r.data.Reminders = make([]domain.WakaReminder, 0)
	}
}

func (r *WakaRepo) Save() error {
	r.mu.Lock()
	defer r.mu.Unlock()

	data, err := json.MarshalIndent(r.data, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(r.filePath, data, 0644)
}

func (r *WakaRepo) GetData() domain.WakaData {
	r.mu.RLock()
	defer r.mu.RUnlock()
	return r.data
}

func (r *WakaRepo) Mutate(fn func(*domain.WakaData)) {
	r.mu.Lock()
	fn(&r.data)
	r.mu.Unlock()
	_ = r.Save()
}
