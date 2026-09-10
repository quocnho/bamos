package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sync"
	"time"
)

type UserMemory struct {
	mu           sync.RWMutex
	filePath     string
	Data         MemoryData
}

type MemoryData struct {
	UserName       string            `json:"user_name"`
	FavoriteTopics map[string]int    `json:"favorite_topics"`
	RecentFiles    []string          `json:"recent_files"`
	WorkHours      map[string]int    `json:"work_hours"` // "morning", "afternoon", "evening", "night"
	TotalQueries   int               `json:"total_queries"`
	LastActive     string            `json:"last_active"`
}

func NewUserMemory() *UserMemory {
	home, _ := os.UserHomeDir()
	dataDir := filepath.Join(home, ".local", "share", "bamos")
	_ = os.MkdirAll(dataDir, 0755)
	memFile := filepath.Join(dataDir, "memory.json")

	um := &UserMemory{
		filePath: memFile,
		Data: MemoryData{
			UserName:       "Chủ nhân",
			FavoriteTopics: make(map[string]int),
			RecentFiles:    make([]string, 0),
			WorkHours:      make(map[string]int),
		},
	}
	um.load()
	return um
}

func (um *UserMemory) load() {
	data, err := os.ReadFile(um.filePath)
	if err == nil {
		_ = json.Unmarshal(data, &um.Data)
	}
	if um.Data.FavoriteTopics == nil {
		um.Data.FavoriteTopics = make(map[string]int)
	}
	if um.Data.WorkHours == nil {
		um.Data.WorkHours = make(map[string]int)
	}
}

func (um *UserMemory) save() {
	data, err := json.MarshalIndent(um.Data, "", "  ")
	if err == nil {
		_ = os.WriteFile(um.filePath, data, 0644)
	}
}

func (um *UserMemory) RecordQuery(query string) {
	um.mu.Lock()
	defer um.mu.Unlock()

	um.Data.TotalQueries++
	um.Data.LastActive = time.Now().Format("2006-01-02 15:04:05")

	// Phân loại khung giờ
	hour := time.Now().Hour()
	var timeSlot string
	switch {
	case hour >= 5 && hour < 12:
		timeSlot = "morning"
	case hour >= 12 && hour < 18:
		timeSlot = "afternoon"
	case hour >= 18 && hour < 23:
		timeSlot = "evening"
	default:
		timeSlot = "night"
	}
	um.Data.WorkHours[timeSlot]++

	um.save()
}

func (um *UserMemory) RecordFileAccess(path string) {
	um.mu.Lock()
	defer um.mu.Unlock()

	// Thêm vào danh sách recent files (tối đa 8 files)
	newRecent := []string{path}
	for _, p := range um.Data.RecentFiles {
		if p != path && len(newRecent) < 8 {
			newRecent = append(newRecent, p)
		}
	}
	um.Data.RecentFiles = newRecent
	um.save()
}

func (um *UserMemory) GetHabitContext() string {
	um.mu.RLock()
	defer um.mu.RUnlock()

	if um.Data.TotalQueries == 0 && len(um.Data.RecentFiles) == 0 {
		return ""
	}

	var contextStr = "=== THÓI QUEN & BỐI CẢNH NGƯỜI DÙNG ===\n"
	if len(um.Data.RecentFiles) > 0 {
		contextStr += "Các tệp tin gần đây người dùng hay làm việc:\n"
		for _, f := range um.Data.RecentFiles {
			contextStr += fmt.Sprintf(" - %s\n", f)
		}
	}
	contextStr += fmt.Sprintf("Tổng số lần tương tác: %d. Lần gần nhất: %s\n", um.Data.TotalQueries, um.Data.LastActive)
	contextStr += "========================================\n"
	return contextStr
}
