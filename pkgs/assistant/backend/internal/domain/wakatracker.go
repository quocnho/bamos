package domain

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

type WakaData struct {
	DailyStats    map[string]*DayStat `json:"daily_stats"`
	ProjectStats  map[string]int      `json:"project_stats"`
	CategoryStats map[string]int      `json:"category_stats"`
	Reminders     []WakaReminder      `json:"reminders"`
	LastDate      string              `json:"last_date"`
}
