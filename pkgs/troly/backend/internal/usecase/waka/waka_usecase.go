package waka

import (
	"context"
	"fmt"
	"os/exec"
	"strings"
	"time"

	"troly/backend/internal/domain"
	"troly/backend/internal/platform/linux"
	"troly/backend/internal/repository/fs"
	"troly/backend/internal/repository/sqlite"
)

type WakaUsecase struct {
	repo    *fs.WakaRepo
	ragRepo *sqlite.RAGRepo
}

func NewWakaUsecase(repo *fs.WakaRepo, ragRepo *sqlite.RAGRepo) *WakaUsecase {
	u := &WakaUsecase{repo: repo, ragRepo: ragRepo}
	go u.startTrackingLoop()
	return u
}

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

func getActiveWindowTitle() string {
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
	apps := linux.GetRunningApps()
	if len(apps) > 0 {
		return apps[0].Name
	}
	return "Mascot Desktop"
}

func (u *WakaUsecase) startTrackingLoop() {
	ticker := time.NewTicker(30 * time.Second)
	for range ticker.C {
		appName := getActiveWindowTitle()
		if appName == "" {
			appName = "BamOS Desktop"
		}
		u.RecordActivity(appName, 30)
	}
}

func (u *WakaUsecase) RecordActivity(appName string, seconds int) {
	today := time.Now().Format("2006-01-02")
	cat := categorizeApp(appName)

	u.repo.Mutate(func(data *domain.WakaData) {
		day, exists := data.DailyStats[today]
		if !exists {
			day = &domain.DayStat{
				AppSeconds: make(map[string]int),
				Categories: make(map[string]int),
			}
			data.DailyStats[today] = day
		}
		day.TotalSeconds += seconds
		day.AppSeconds[appName] += seconds
		day.Categories[cat] += seconds
		data.CategoryStats[cat] += seconds
	})
}

func (u *WakaUsecase) AddReminder(title, dueTime string) domain.WakaReminder {
	r := domain.WakaReminder{
		ID:        fmt.Sprintf("rem_%d", time.Now().UnixNano()),
		Title:     title,
		DueTime:   dueTime,
		Completed: false,
		CreatedAt: time.Now().Format("2006-01-02 15:04"),
	}
	u.repo.Mutate(func(data *domain.WakaData) {
		data.Reminders = append(data.Reminders, r)
	})
	return r
}

func (u *WakaUsecase) ToggleReminder(id string) {
	u.repo.Mutate(func(data *domain.WakaData) {
		for i := range data.Reminders {
			if data.Reminders[i].ID == id {
				data.Reminders[i].Completed = !data.Reminders[i].Completed
				break
			}
		}
	})
}

func (u *WakaUsecase) GetSummary() map[string]any {
	data := u.repo.GetData()
	today := time.Now().Format("2006-01-02")
	todayStat, exists := data.DailyStats[today]
	todaySec := 0
	todayApps := make(map[string]int)
	todayCats := make(map[string]int)

	if exists {
		todaySec = todayStat.TotalSeconds
		todayApps = todayStat.AppSeconds
		todayCats = todayStat.Categories
	}

	sevenDaysTotalSec := 0
	for i := 0; i < 7; i++ {
		date := time.Now().AddDate(0, 0, -i).Format("2006-01-02")
		if stat, ok := data.DailyStats[date]; ok {
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
		"reminders":           data.Reminders,
	}
}

func (u *WakaUsecase) GetSummaryContext() string {
	sum := u.GetSummary()
	var sb strings.Builder
	sb.WriteString("=== THỐNG KÊ HOẠT ĐỘNG & NĂNG SUẤT LÀM VIỆC (WAKATIME) ===\n")
	sb.WriteString(fmt.Sprintf("- Thời gian làm việc hôm nay (%s): %s (khoảng %d phút)\n", sum["today_date"], sum["today_hours_text"], sum["today_total_minutes"]))
	sb.WriteString(fmt.Sprintf("- Tổng thời gian làm việc trong 7 ngày qua: %s\n", sum["seven_days_hours"]))

	if apps, ok := sum["today_apps"].(map[string]int); ok && len(apps) > 0 {
		sb.WriteString("- Các ứng dụng làm việc hôm nay:\n")
		for app, sec := range apps {
			if sec >= 60 {
				sb.WriteString(fmt.Sprintf("  + %s: %d phút\n", app, sec/60))
			}
		}
	}

	data := u.repo.GetData()
	pendingCount := 0
	for _, r := range data.Reminders {
		if !r.Completed {
			pendingCount++
		}
	}

	if pendingCount > 0 {
		sb.WriteString(fmt.Sprintf("- Danh sách lời nhắc / việc cần làm chưa hoàn thành (%d việc):\n", pendingCount))
		for _, r := range data.Reminders {
			if !r.Completed {
				due := ""
				if r.DueTime != "" {
					due = fmt.Sprintf(" (Hạn: %s)", r.DueTime)
				}
				sb.WriteString(fmt.Sprintf("  * [Cần làm] %s%s\n", r.Title, due))
			}
		}
	}
	sb.WriteString("=========================================================")
	return sb.String()
}

func (u *WakaUsecase) SyncToRAG(ctx context.Context) {
	if u.ragRepo == nil {
		return
	}
	content := u.GetSummaryContext()
	_ = u.ragRepo.IndexDocument(ctx, "wakatracker_activity_knowledge", content, map[string]string{
		"source": "wakatracker",
		"title":  "Thống kê hoạt động & Năng suất WakaTime",
		"domain": "waka_activity",
	})
}
