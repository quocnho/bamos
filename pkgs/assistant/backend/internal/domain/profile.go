package domain

import "strings"

type UserPreferences struct {
	ThemeColor string `json:"theme_color"` // "teal", "amber", "cyan", "purple", "rose"
	ThemeMode  string `json:"theme_mode"`  // "dark", "light", "oled", "cyberpunk"
	NightLight bool   `json:"night_light"`
	SoundChime bool   `json:"sound_chime"`
}

type RoadmapStep struct {
	ID          int    `json:"id"`
	Domain      string `json:"domain"`
	Title       string `json:"title"`
	Description string `json:"description"`
	Completed   bool   `json:"completed"`
}

type QuizQuestion struct {
	ID       int      `json:"id"`
	Domain   string   `json:"domain"`
	Question string   `json:"question"`
	Options  []string `json:"options"`
	Answer   int      `json:"answer"` // 0-indexed
}

type UserProfileData struct {
	FullName     string          `json:"full_name"`
	Age          int             `json:"age"`
	Email        string          `json:"email"`
	Phone        string          `json:"phone"`
	Addressing   string          `json:"addressing"` // "Chủ nhân", "Anh", "Chị", "Ông", "Bà", "Bạn", hoặc tự nhập
	Domains      []string        `json:"domains"`    // Chọn tối đa 3 lĩnh vực quan tâm
	CurrentLevel string          `json:"current_level"`
	QuizScore    int             `json:"quiz_score"`
	TotalQuiz    int             `json:"total_quiz"`
	AssessmentAt string          `json:"assessment_at"`
	RoadmapSteps []RoadmapStep   `json:"roadmap_steps"`
	Preferences  UserPreferences `json:"preferences"`
}

var AvailableDomains = []string{
	"Công nghệ thông tin & Phát triển phần mềm",
	"Dữ liệu & Trí tuệ nhân tạo (AI / Data)",
	"Kỹ thuật & Tự động hóa (Cơ khí, Điện tử, Xây dựng...)",
	"Sản xuất & Vận hành chuỗi cung ứng (Manufacturing / Supply Chain)",
	"Marketing, Truyền thông & Quan hệ công chúng (PR)",
	"Bán hàng & Phát triển kinh doanh (Sales / BD)",
	"Tài chính, Kế toán & Kiểm toán",
	"Nhân sự, Tuyển dụng & Đào tạo nội bộ (HR)",
	"Thiết kế, Nghệ thuật & Sáng tạo nội dung (UI/UX, Đồ họa, Video...)",
	"Pháp chế & Tuân thủ (Legal & Compliance)",
	"Y tế, Dược phẩm & Chăm sóc sức khỏe",
	"Giáo dục, Giảng dạy & Nghiên cứu (R&D)",
	"Quản trị & Điều hành chung (C-Level, Founder, Quản lý tổng quát)",
}

// GetAddressingPronouns trả về (userTitle, assistantTitle) dựa trên cách xưng hô
func GetAddressingPronouns(addressing string) (string, string) {
	addr := strings.TrimSpace(addressing)
	if addr == "" {
		addr = "Bạn"
	}
	switch strings.ToLower(addr) {
	case "chủ nhân":
		return "Chủ nhân", "Em"
	case "anh":
		return "Anh", "Em"
	case "chị":
		return "Chị", "Em"
	case "ông":
		return "Ông", "Cháu"
	case "bà":
		return "Bà", "Cháu"
	case "bạn":
		return "Bạn", "Tôi"
	default:
		return addr, "Em"
	}
}
