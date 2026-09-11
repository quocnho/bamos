package main

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sync"
	"time"
)

// UserProfileManager quản lý thông tin đăng ký của người dùng,
// bài kiểm tra năng lực (Onboarding Assessment) và lộ trình nâng cao kiến thức.
type UserProfileManager struct {
	mu       sync.RWMutex
	filePath string
	rag      *RAGManager
	Profile  UserProfileData `json:"profile"`
}

type UserProfileData struct {
	FullName      string          `json:"full_name"`
	Age           int             `json:"age"`
	Email         string          `json:"email"`
	Phone         string          `json:"phone"`
	Addressing    string          `json:"addressing"` // "Chủ nhân", "Anh", "Chị", "Bạn"...
	Domains       []string        `json:"domains"`    // "NixOS & Linux", "Backend Golang", "AI & RAG"...
	CurrentLevel  string          `json:"current_level"` // "Newbie", "Junior", "Intermediate", "Senior"
	QuizScore     int             `json:"quiz_score"`
	TotalQuiz     int             `json:"total_quiz"`
	AssessmentAt  string          `json:"assessment_at"`
	RoadmapSteps  []RoadmapStep   `json:"roadmap_steps"`
	Preferences   UserPreferences `json:"preferences"`
}

type UserPreferences struct {
	ThemeColor  string `json:"theme_color"`  // "teal", "amber", "cyan", "purple", "rose"
	ThemeMode   string `json:"theme_mode"`   // "dark", "light", "oled", "cyberpunk"
	NightLight  bool   `json:"night_light"`
	SoundChime  bool   `json:"sound_chime"`
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

func NewUserProfileManager(rag *RAGManager) *UserProfileManager {
	home, _ := os.UserHomeDir()
	dir := filepath.Join(home, ".local", "share", "bamos")
	_ = os.MkdirAll(dir, 0755)
	file := filepath.Join(dir, "user_profile.json")

	upm := &UserProfileManager{
		filePath: file,
		rag:      rag,
		Profile: UserProfileData{
			FullName:     "Chủ nhân",
			Addressing:   "Chủ nhân",
			CurrentLevel: "Chưa đánh giá",
			Domains:      []string{"NixOS & Linux", "Lập trình Backend", "AI & RAG"},
			Preferences: UserPreferences{
				ThemeColor: "teal",
				ThemeMode:  "dark",
				NightLight: true,
				SoundChime: true,
			},
		},
	}
	upm.load()
	return upm
}

func (upm *UserProfileManager) load() {
	upm.mu.Lock()
	defer upm.mu.Unlock()

	data, err := os.ReadFile(upm.filePath)
	if err == nil {
		_ = json.Unmarshal(data, &upm.Profile)
	}
	if len(upm.Profile.Domains) == 0 {
		upm.Profile.Domains = []string{"NixOS & Linux", "Lập trình Backend", "AI & RAG"}
	}
}

func (upm *UserProfileManager) save() {
	data, err := json.MarshalIndent(upm.Profile, "", "  ")
	if err == nil {
		_ = os.WriteFile(upm.filePath, data, 0644)
	}
}

// GetQuizQuestions sinh bộ câu hỏi trắc nghiệm đánh giá nhanh dựa trên lĩnh vực
func (upm *UserProfileManager) GetQuizQuestions() []QuizQuestion {
	return []QuizQuestion{
		{
			ID:       1,
			Domain:   "NixOS & Linux",
			Question: "Trong NixOS, file nào là trung tâm cấu hình toàn bộ hệ điều hành, dịch vụ và gói ứng dụng?",
			Options: []string{
				"/etc/nixos/configuration.nix",
				"/etc/fstab",
				"/etc/default/grub",
				"/var/log/syslog",
			},
			Answer: 0,
		},
		{
			ID:       2,
			Domain:   "NixOS & Linux",
			Question: "Lệnh nào dùng để áp dụng cấu hình mới trong NixOS và lưu lại vào danh sách boot?",
			Options: []string{
				"sudo nixos-rebuild switch",
				"systemctl restart all",
				"apt update && apt upgrade",
				"nix-env -iA nixpkgs",
			},
			Answer: 0,
		},
		{
			ID:       3,
			Domain:   "Lập trình Backend & Go",
			Question: "Tính năng nào trong Golang giúp xử lý hàng triệu tác vụ đồng thời mà tiêu tốn cực ít bộ nhớ RAM?",
			Options: []string{
				"Goroutines & Channels",
				"Async / Await Promise",
				"Multi-threading POSIX (pthread)",
				"Callback Hell",
			},
			Answer: 0,
		},
		{
			ID:       4,
			Domain:   "AI & RAG",
			Question: "Kỹ thuật Hybrid Search trong RAG kết hợp hai phương thức tìm kiếm nào để đạt độ chính xác tối ưu?",
			Options: []string{
				"Lexical Search (BM25/FTS5) + Dense Vector Embedding",
				"Binary Search + Hash Map",
				"Regex Match + SQL Like %%",
				"Random Walk + BFS Search",
			},
			Answer: 0,
		},
	}
}

// SubmitAssessment chấm điểm bài test, phân level và tạo lộ trình nâng cấp kiến thức
func (upm *UserProfileManager) SubmitAssessment(answers map[int]int) map[string]any {
	upm.mu.Lock()
	defer upm.mu.Unlock()

	questions := upm.GetQuizQuestions()
	score := 0
	for _, q := range questions {
		if ans, ok := answers[q.ID]; ok && ans == q.Answer {
			score++
		}
	}

	total := len(questions)
	level := "Newbie (Mới bắt đầu)"
	if score == total {
		level = "Senior / Expert (Chuyên gia)"
	} else if score >= 3 {
		level = "Intermediate (Có kinh nghiệm)"
	} else if score >= 2 {
		level = "Junior (Cơ bản vững)"
	}

	upm.Profile.QuizScore = score
	upm.Profile.TotalQuiz = total
	upm.Profile.CurrentLevel = level
	upm.Profile.AssessmentAt = time.Now().Format("2006-01-02 15:04")

	// Tạo lộ trình nâng cao năng lực cá nhân
	upm.Profile.RoadmapSteps = []RoadmapStep{
		{
			ID:          1,
			Domain:      "NixOS",
			Title:       "Làm chủ Flakes và Home Manager",
			Description: "Chuyển cấu hình `/etc/nixos/` sang kiến trúc Flakes mô-đun hoá cao cấp.",
			Completed:   false,
		},
		{
			ID:          2,
			Domain:      "AI & RAG",
			Title:       "Tối ưu Hybrid Search & Embeddings Cục bộ",
			Description: "Huấn luyện và fine-tune mô hình Embedding tiếng Việt với sqlite-vec.",
			Completed:   false,
		},
		{
			ID:          3,
			Domain:      "Hệ thống",
			Title:       "Tự động hoá giám sát & Tối ưu hoá RAM",
			Description: "Viết script tự động phát hiện ứng dụng chạy ngầm rò rỉ bộ nhớ.",
			Completed:   false,
		},
	}

	upm.save()

	// Tự động index hồ sơ và trình độ người dùng vào RAG để LLM thấu hiểu
	if upm.rag != nil {
		go func() {
			_ = upm.rag.IndexDocument(context.Background(), "user_profile_knowledge",
				fmt.Sprintf("Hồ sơ Chủ nhân: %s. Trình độ hiện tại: %s (Đạt %d/%d điểm kiểm tra). Lĩnh vực quan tâm: %s. Cách xưng hô yêu thích: %s.",
					upm.Profile.FullName, level, score, total, fmt.Sprintf("%v", upm.Profile.Domains), upm.Profile.Addressing),
				map[string]string{
					"source": "user_profile",
					"title":  "Hồ sơ & Trình độ người dùng",
					"domain": "user_profile",
				},
			)
		}()
	}

	return map[string]any{
		"score":   score,
		"total":   total,
		"level":   level,
		"roadmap": upm.Profile.RoadmapSteps,
	}
}

// UpdateProfile cập nhật thông tin cá nhân và sở thích
func (upm *UserProfileManager) UpdateProfile(p UserProfileData) {
	upm.mu.Lock()
	defer upm.mu.Unlock()

	if p.FullName != "" {
		upm.Profile.FullName = p.FullName
	}
	if p.Age > 0 {
		upm.Profile.Age = p.Age
	}
	if p.Email != "" {
		upm.Profile.Email = p.Email
	}
	if p.Phone != "" {
		upm.Profile.Phone = p.Phone
	}
	if p.Addressing != "" {
		upm.Profile.Addressing = p.Addressing
	}
	if len(p.Domains) > 0 {
		upm.Profile.Domains = p.Domains
	}
	if p.Preferences.ThemeColor != "" {
		upm.Profile.Preferences = p.Preferences
	}

	upm.save()
}
