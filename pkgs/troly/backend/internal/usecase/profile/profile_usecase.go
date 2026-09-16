package profile

import (
	"context"
	"fmt"
	"strings"
	"time"

	"troly/backend/internal/domain"
	"troly/backend/internal/repository/fs"
	"troly/backend/internal/repository/sqlite"
)

type ProfileUsecase struct {
	repo    *fs.ProfileRepo
	ragRepo *sqlite.RAGRepo
}

func NewProfileUsecase(repo *fs.ProfileRepo, ragRepo *sqlite.RAGRepo) *ProfileUsecase {
	u := &ProfileUsecase{repo: repo, ragRepo: ragRepo}
	u.SyncToRAG(context.Background())
	return u
}

func (u *ProfileUsecase) GetProfile() domain.UserProfileData {
	return u.repo.Get()
}

func (u *ProfileUsecase) GetQuizQuestions() []domain.QuizQuestion {
	return []domain.QuizQuestion{
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

func (u *ProfileUsecase) SubmitAssessment(answers map[int]int) map[string]any {
	questions := u.GetQuizQuestions()
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

	prof := u.repo.Get()
	prof.QuizScore = score
	prof.TotalQuiz = total
	prof.CurrentLevel = level
	prof.AssessmentAt = time.Now().Format("2006-01-02 15:04")
	prof.RoadmapSteps = []domain.RoadmapStep{
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
	u.repo.Set(prof)
	u.SyncToRAG(context.Background())

	return map[string]any{
		"score":   score,
		"total":   total,
		"level":   level,
		"roadmap": prof.RoadmapSteps,
	}
}

func (u *ProfileUsecase) UpdateProfile(p domain.UserProfileData) {
	curr := u.repo.Get()
	if p.FullName != "" {
		curr.FullName = p.FullName
	}
	if p.Age > 0 {
		curr.Age = p.Age
	}
	if p.Email != "" {
		curr.Email = p.Email
	}
	if p.Phone != "" {
		curr.Phone = p.Phone
	}
	if p.Addressing != "" {
		curr.Addressing = p.Addressing
	}
	if len(p.Domains) > 0 {
		if len(p.Domains) > 3 {
			curr.Domains = p.Domains[:3]
		} else {
			curr.Domains = p.Domains
		}
	}
	if p.Preferences.ThemeColor != "" {
		curr.Preferences = p.Preferences
	}
	u.repo.Set(curr)
	u.SyncToRAG(context.Background())
}

func (u *ProfileUsecase) GetPromptContext() string {
	p := u.repo.Get()
	userTitle, botTitle := domain.GetAddressingPronouns(p.Addressing)

	var sb strings.Builder
	sb.WriteString("=== HỒ SƠ & DANH TÍNH NGƯỜI DÙNG (USER PROFILE) ===\n")
	if p.FullName != "" {
		sb.WriteString(fmt.Sprintf("- Họ và tên: %s\n", p.FullName))
	}
	if p.Age > 0 {
		sb.WriteString(fmt.Sprintf("- Tuổi: %d\n", p.Age))
	}
	if p.Email != "" {
		sb.WriteString(fmt.Sprintf("- Email: %s\n", p.Email))
	}
	if p.Phone != "" {
		sb.WriteString(fmt.Sprintf("- Số điện thoại: %s\n", p.Phone))
	}
	sb.WriteString(fmt.Sprintf("- Danh xưng người dùng: %s\n", userTitle))
	sb.WriteString(fmt.Sprintf("- Ngôi xưng của Trợ lý: %s\n", botTitle))

	if p.CurrentLevel != "" {
		sb.WriteString(fmt.Sprintf("- Trình độ chuyên môn: %s", p.CurrentLevel))
		if p.TotalQuiz > 0 {
			sb.WriteString(fmt.Sprintf(" (Đạt %d/%d điểm kiểm tra năng lực)\n", p.QuizScore, p.TotalQuiz))
		} else {
			sb.WriteString("\n")
		}
	}
	if len(p.Domains) > 0 {
		sb.WriteString(fmt.Sprintf("- 3 lĩnh vực quan tâm hàng đầu: %s\n", strings.Join(p.Domains, ", ")))
	}
	if len(p.RoadmapSteps) > 0 {
		sb.WriteString("- Lộ trình kỹ năng cá nhân hoá:\n")
		for _, step := range p.RoadmapSteps {
			status := "Chưa hoàn thành"
			if step.Completed {
				status = "Đã hoàn thành"
			}
			sb.WriteString(fmt.Sprintf("  + [%s] %s: %s (%s)\n", step.Domain, step.Title, step.Description, status))
		}
	}
	sb.WriteString("QUY TẮC BẮT BUỘC VỀ XƯNG HÔ VÀ DANH TÍNH:\n")
	sb.WriteString(fmt.Sprintf("- Khi trò chuyện, bạn BẮT BUỘC gọi người dùng là \"%s\" (hoặc \"%s ơi\", \"%s ạ\"), và tự xưng là \"%s\". TUYỆT ĐỐI KHÔNG dùng từ ngữ xưng hô khác làm sai lệch thiết lập này.\n", userTitle, userTitle, userTitle, botTitle))
	sb.WriteString(fmt.Sprintf("- Khi người dùng hỏi 'tôi tên gì', 'tôi là ai', 'thông tin của tôi', bạn PHẢI nhận diện người dùng chính là %s %s có hồ sơ nêu trên, trả lời thân thiện, chính xác và lịch thiệp.\n", userTitle, p.FullName))
	sb.WriteString("====================================================")
	return sb.String()
}

func (u *ProfileUsecase) SyncToRAG(ctx context.Context) {
	if u.ragRepo == nil {
		return
	}
	p := u.repo.Get()
	var sb strings.Builder
	sb.WriteString("Thông tin hồ sơ cá nhân của Chủ nhân:\n")
	sb.WriteString(fmt.Sprintf("- Họ tên đầy đủ: %s\n", p.FullName))
	if p.Age > 0 {
		sb.WriteString(fmt.Sprintf("- Tuổi: %d\n", p.Age))
	}
	if p.Email != "" {
		sb.WriteString(fmt.Sprintf("- Email liên hệ: %s\n", p.Email))
	}
	if p.Phone != "" {
		sb.WriteString(fmt.Sprintf("- Số điện thoại: %s\n", p.Phone))
	}
	sb.WriteString(fmt.Sprintf("- Cách xưng hô: %s\n", p.Addressing))
	sb.WriteString(fmt.Sprintf("- Trình độ chuyên môn: %s\n", p.CurrentLevel))
	if len(p.Domains) > 0 {
		sb.WriteString(fmt.Sprintf("- Các lĩnh vực quan tâm: %s\n", strings.Join(p.Domains, ", ")))
	}
	if len(p.RoadmapSteps) > 0 {
		sb.WriteString("- Lộ trình học tập & phát triển kiến thức:\n")
		for _, step := range p.RoadmapSteps {
			sb.WriteString(fmt.Sprintf("  * %s (%s): %s\n", step.Title, step.Domain, step.Description))
		}
	}

	_ = u.ragRepo.IndexDocument(ctx, "user_profile_knowledge", sb.String(), map[string]string{
		"source": "user_profile",
		"title":  fmt.Sprintf("Hồ sơ cá nhân & Trình độ của %s", p.FullName),
		"domain": "user_profile",
	})
}
