package sqlite

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sync"
	"time"
)

type CommandMemo struct {
	Description string `json:"description"`
	Count       int    `json:"count"`
	LastUsed    string `json:"last_used"`
}

type MemoryData struct {
	UserName        string                 `json:"user_name"`
	FavoriteTopics  map[string]int         `json:"favorite_topics"`
	RecentFiles     []string               `json:"recent_files"`
	LearnedCommands map[string]CommandMemo `json:"learned_commands"`
	ActiveDirectory string                 `json:"active_directory"`
	WorkHours       map[string]int         `json:"work_hours"`
	TotalQueries    int                    `json:"total_queries"`
	LastActive      string                 `json:"last_active"`
}

type MemoryRepo struct {
	mu       sync.RWMutex
	filePath string
	Data     MemoryData
}

func NewMemoryRepo() *MemoryRepo {
	home, _ := os.UserHomeDir()
	dataDir := filepath.Join(home, ".local", "share", "bamos")
	_ = os.MkdirAll(dataDir, 0755)
	memFile := filepath.Join(dataDir, "memory.json")

	mr := &MemoryRepo{
		filePath: memFile,
		Data: MemoryData{
			UserName:        "Chủ nhân",
			FavoriteTopics:  make(map[string]int),
			RecentFiles:     make([]string, 0),
			LearnedCommands: make(map[string]CommandMemo),
			WorkHours:       make(map[string]int),
		},
	}
	mr.load()
	return mr
}

func (mr *MemoryRepo) load() {
	data, err := os.ReadFile(mr.filePath)
	if err == nil {
		_ = json.Unmarshal(data, &mr.Data)
	}
	if mr.Data.FavoriteTopics == nil {
		mr.Data.FavoriteTopics = make(map[string]int)
	}
	if mr.Data.LearnedCommands == nil {
		mr.Data.LearnedCommands = make(map[string]CommandMemo)
	}
	if mr.Data.WorkHours == nil {
		mr.Data.WorkHours = make(map[string]int)
	}
}

func (mr *MemoryRepo) save() {
	data, err := json.MarshalIndent(mr.Data, "", "  ")
	if err == nil {
		_ = os.WriteFile(mr.filePath, data, 0644)
	}
}

func (mr *MemoryRepo) LearnCommand(cmd string, desc string) {
	mr.mu.Lock()
	defer mr.mu.Unlock()

	memo, exists := mr.Data.LearnedCommands[cmd]
	if !exists {
		memo = CommandMemo{
			Description: desc,
			Count:       1,
			LastUsed:    time.Now().Format("2006-01-02 15:04:05"),
		}
	} else {
		memo.Count++
		memo.LastUsed = time.Now().Format("2006-01-02 15:04:05")
		if desc != "" {
			memo.Description = desc
		}
	}
	mr.Data.LearnedCommands[cmd] = memo
	mr.save()
}

func (mr *MemoryRepo) GetLearnedCommand(cmd string) (string, bool) {
	mr.mu.RLock()
	defer mr.mu.RUnlock()

	memo, exists := mr.Data.LearnedCommands[cmd]
	if !exists {
		return "", false
	}
	return fmt.Sprintf("%s (đã dùng %d lần)", memo.Description, memo.Count), true
}

func (mr *MemoryRepo) SetActiveDirectory(dir string) {
	mr.mu.Lock()
	defer mr.mu.Unlock()
	mr.Data.ActiveDirectory = dir
	mr.save()
}

func (mr *MemoryRepo) GetActiveDirectory() string {
	mr.mu.RLock()
	defer mr.mu.RUnlock()
	return mr.Data.ActiveDirectory
}

func (mr *MemoryRepo) RecordQuery(query string) {
	mr.mu.Lock()
	defer mr.mu.Unlock()

	mr.Data.TotalQueries++
	mr.Data.LastActive = time.Now().Format("2006-01-02 15:04:05")

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
	mr.Data.WorkHours[timeSlot]++
	mr.save()
}

func (mr *MemoryRepo) RecordFileAccess(path string) {
	mr.mu.Lock()
	defer mr.mu.Unlock()

	newRecent := []string{path}
	for _, p := range mr.Data.RecentFiles {
		if p != path && len(newRecent) < 8 {
			newRecent = append(newRecent, p)
		}
	}
	mr.Data.RecentFiles = newRecent
	mr.save()
}

func (mr *MemoryRepo) GetHabitContext() string {
	mr.mu.RLock()
	defer mr.mu.RUnlock()

	if mr.Data.TotalQueries == 0 && len(mr.Data.RecentFiles) == 0 {
		return ""
	}

	var contextStr = "=== THÓI QUEN & BỐI CẢNH CỦA CHỦ NHÂN ===\n"
	if len(mr.Data.RecentFiles) > 0 {
		contextStr += "Các tệp tin gần đây Chủ nhân hay làm việc:\n"
		for _, f := range mr.Data.RecentFiles {
			contextStr += fmt.Sprintf(" - %s\n", f)
		}
	}
	contextStr += fmt.Sprintf("Tổng số lần Chủ nhân tương tác: %d. Lần gần nhất: %s\n", mr.Data.TotalQueries, mr.Data.LastActive)
	contextStr += "==========================================\n"
	return contextStr
}
