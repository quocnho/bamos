package main

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"
	"time"
)

// WakaTracker theo dõi thời gian hoạt động theo phong cách WakaTime:
// - Thống kê thời gian làm việc theo ứng dụng, dự án/thư mục và danh mục
// - Hỗ trợ tạo lịch hẹn, quản lý công việc (To-Do / Reminders)
// - Báo cáo năng suất ngày, tuần, tháng
type WakaTracker struct {
	mu           sync.RWMutex
	filePath     string
	data         WakaData
	currentApp   string
	currentStart time.Time
}

type WakaData struct {
	DailyStats    map[string]*DayStat `json:"daily_stats"`    // "2026-09-11" -> DayStat
	ProjectStats  map[string]int      `json:"project_stats"`  // Thư mục/Project -> Tổng giây
	CategoryStats map[string]int      `json:"category_stats"` // "Lập trình", "Duyệt web", "Hệ thống" -> Tổng giây
	Reminders     []WakaReminder      `json:"reminders"`
	LastDate      string              `json:"last_date"`
}

type DayStat struct {
	TotalSeconds int            `json:"total_seconds"`
	AppSeconds   map[string]int `json:"app_seconds"`
	Categories   map[string]int `json:"categories"`
}

type WakaReminder struct {
	ID        string `json:"id"`
	Title     string `json:"title"`
	DueTime   string `json:"due_time"` // "15:30" hoặc "2026-09-11 15:30"
	Completed bool   `json:"completed"`
	CreatedAt string `json:"created_at"`
}

func NewWakaTracker() *WakaTracker {
	home, _ := os.UserHomeDir()
	dir := filepath.Join(home, ".local", "share", "bamos")
	_ = os.MkdirAll(dir, 0755)
	file := filepath.Join(dir, "wakatracker.json")

	wt := &WakaTracker{
		filePath: file,
		data: WakaData{
			DailyStats:    make(map[string]*DayStat),
			ProjectStats:  make(map[string]int),
			CategoryStats: make(map[string]int),
			Reminders:     make([]WakaReminder, 0),
		},
		currentStart: time.Now(),
	}
	wt.load()
	go wt.startTrackingLoop()
	return wt
}

func (wt *WakaTracker) load() {
	wt.mu.Lock()
	defer wt.mu.Unlock()

	data, err := os.ReadFile(wt.filePath)
	if err == nil {
		_ = json.Unmarshal(data, &wt.data)
	}
	if wt.data.DailyStats == nil {
		wt.data.DailyStats = make(map[string]*DayStat)
	}
	if wt.data.ProjectStats == nil {
		wt.data.ProjectStats = make(map[string]int)
	}
	if wt.data.CategoryStats == nil {
		wt.data.CategoryStats = make(map[string]int)
	}
	if wt.data.Reminders == nil {
		wt.data.Reminders = make([]WakaReminder, 0)
	}
}

func (wt *WakaTracker) save() {
	data, err := json.MarshalIndent(wt.data, "", "  ")
	if err == nil {
		_ = os.WriteFile(wt.filePath, data, 0644)
	}
}

// categorizeApp phân loại danh mục theo tên ứng dụng
func categorizeApp(appName string) string {
	lower := strings.ToLower(appName)
	switch {
	case strings.Contains(lower, "antigravity") || strings.Contains(lower, "code") || strings.Contains(lower, "zed") || strings.Contains(lower, "terminal") || strings.Contains(lower, "nvim"):
		return "Lập trình & Phát triển"
	case strings.Contains(lower, "firefox") || strings.Contains(lower, "chrome") || strings.Contains(lower, "browser"):
		return "Nghiên cứu & Web"
	case strings.Contains(lower, "nautilus") || strings.Contains(lower, "gnome") || strings.Contains(lower, "settings"):
		return "Quản trị Hệ thống"
	default:
		return "Tác vụ Khác"
	}
}

// getActiveWindowTitle lấy tiêu đề cửa sổ đang active trên GNOME Wayland/X11
func getActiveWindowTitle() string {
	// Thử dùng gdbus để truy vấn GNOME Shell Mutter nếu có
	out, err := exec.Command("bash", "-c", `gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell --method org.gnome.Shell.Eval "global.display.focus_window ? global.display.focus_window.get_title() : ''" 2>/dev/null`).Output()
	if err == nil {
		str := string(out)
		if strings.Contains(str, "(") {
			parts := strings.Split(str, "'")
			if len(parts) >= 2 {
				return parts[1]
			}
		}
	}
	// Fallback kiểm tra các tiến trình đang có CPU > 0
	apps := GetRunningApps()
	if len(apps) > 0 {
		return apps[0].Name
	}
	return "Mascot Desktop"
}

// startTrackingLoop cập nhật số giây hoạt động định kỳ mỗi 30 giây
func (wt *WakaTracker) startTrackingLoop() {
	ticker := time.NewTicker(30 * time.Second)
	for range ticker.C {
		appName := getActiveWindowTitle()
		if appName == "" {
			appName = "BamOS Desktop"
		}
		wt.RecordActivity(appName, 30)
	}
}

// RecordActivity ghi nhận thời gian làm việc
func (wt *WakaTracker) RecordActivity(appName string, seconds int) {
	wt.mu.Lock()
	defer wt.mu.Unlock()

	today := time.Now().Format("2006-01-02")
	cat := categorizeApp(appName)

	day, exists := wt.data.DailyStats[today]
	if !exists {
		day = &DayStat{
			AppSeconds: make(map[string]int),
			Categories: make(map[string]int),
		}
		wt.data.DailyStats[today] = day
	}

	day.TotalSeconds += seconds
	day.AppSeconds[appName] += seconds
	day.Categories[cat] += seconds

	wt.data.CategoryStats[cat] += seconds
	wt.save()
}

// AddReminder thêm một lời nhắc việc hoặc lịch hẹn
func (wt *WakaTracker) AddReminder(title, dueTime string) WakaReminder {
	wt.mu.Lock()
	defer wt.mu.Unlock()

	r := WakaReminder{
		ID:        fmt.Sprintf("rem_%d", time.Now().UnixNano()),
		Title:     title,
		DueTime:   dueTime,
		Completed: false,
		CreatedAt: time.Now().Format("2006-01-02 15:04"),
	}
	wt.data.Reminders = append(wt.data.Reminders, r)
	wt.save()
	return r
}

// ToggleReminder đánh dấu hoàn thành lời nhắc
func (wt *WakaTracker) ToggleReminder(id string) {
	wt.mu.Lock()
	defer wt.mu.Unlock()

	for i := range wt.data.Reminders {
		if wt.data.Reminders[i].ID == id {
			wt.data.Reminders[i].Completed = !wt.data.Reminders[i].Completed
			break
		}
	}
	wt.save()
}

// GetSummary thống kê thời gian làm việc hôm nay và 7 ngày qua
func (wt *WakaTracker) GetSummary() map[string]any {
	wt.mu.RLock()
	defer wt.mu.RUnlock()

	today := time.Now().Format("2006-01-02")
	todayStat, exists := wt.data.DailyStats[today]
	todaySec := 0
	todayApps := make(map[string]int)
	todayCats := make(map[string]int)

	if exists {
		todaySec = todayStat.TotalSeconds
		todayApps = todayStat.AppSeconds
		todayCats = todayStat.Categories
	}

	// Tính 7 ngày qua
	sevenDaysTotalSec := 0
	for i := 0; i < 7; i++ {
		date := time.Now().AddDate(0, 0, -i).Format("2006-01-02")
		if stat, ok := wt.data.DailyStats[date]; ok {
			sevenDaysTotalSec += stat.TotalSeconds
		}
	}

	return map[string]any{
		"today_date":          today,
		"today_total_minutes": todaySec / 60,
		"today_hours_text":    fmt.Sprintf("%.1f giờ", float64(todaySec)/3600.0),
		"seven_days_hours":    fmt.Sprintf("%.1f giờ", float64(sevenDaysTotalSec)/3600.0),
		"today_apps":          todayApps,
		"today_categories":    todayCats,
		"reminders":           wt.data.Reminders,
	}
}
