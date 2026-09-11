package main

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"
	"time"
)

// SystemInspector thực hiện quét log hệ thống (journalctl),
// kiểm tra cấu hình NixOS (/etc/nixos), và phát hiện các ứng dụng chạy ngầm không sử dụng.
type SystemInspector struct {
	mu            sync.RWMutex
	lastCheckTime time.Time
	rag           *RAGManager
	mem           *UserMemory
	active        bool
}

type SystemIssue struct {
	ID          string `json:"id"`
	Type        string `json:"type"`     // "nixos_config", "systemd_error", "idle_app", "hardware_warning"
	Severity    string `json:"severity"` // "error", "warning", "info"
	Title       string `json:"title"`
	Description string `json:"description"`
	Suggestion  string `json:"suggestion"`
	FixCommand  string `json:"fix_command,omitempty"`
	Timestamp   string `json:"timestamp"`
}

type IdleAppReport struct {
	PID         string `json:"pid"`
	Name        string `json:"name"`
	Command     string `json:"command"`
	MemoryMB    string `json:"memory_mb"`
	IdleTimeMin int    `json:"idle_time_min"`
	Suggestion  string `json:"suggestion"`
}

func NewSystemInspector(rag *RAGManager, mem *UserMemory) *SystemInspector {
	return &SystemInspector{
		rag:    rag,
		mem:    mem,
		active: true,
	}
}

// InspectRecentLogs quét nhật ký journalctl gần nhất để tìm lỗi nghiêm trọng (error, critical)
func (si *SystemInspector) InspectRecentLogs(ctx context.Context) ([]SystemIssue, error) {
	var issues []SystemIssue

	// Lấy log mức độ error (p 3) trong boot hiện tại (-b)
	cmd := exec.CommandContext(ctx, "journalctl", "-p", "3", "-xb", "--no-pager", "-n", "20")
	out, err := cmd.Output()
	if err != nil {
		return issues, nil
	}

	lines := strings.Split(strings.TrimSpace(string(out)), "\n")
	seenPatterns := make(map[string]bool)

	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line == "" || strings.HasPrefix(line, "--") {
			continue
		}

		// Lọc ra các thông điệp lỗi tiêu biểu
		var title, suggestion string
		lower := strings.ToLower(line)

		if strings.Contains(lower, "failed to start") || strings.Contains(lower, "unit") && strings.Contains(lower, "failed") {
			title = "Dịch vụ Systemd khởi động thất bại"
			suggestion = "Kiểm tra lại cấu hình systemd service trong `/etc/nixos/` hoặc dùng lệnh `systemctl status <tên_service>`"
		} else if strings.Contains(lower, "out of memory") || strings.Contains(lower, "oom") {
			title = "Cảnh báo cạn kiệt bộ nhớ (OOM Killer)"
			suggestion = "Một ứng dụng vừa bị hệ thống dừng do thiếu RAM. Hãy cân nhắc tăng swap hoặc đóng ứng dụng ngầm."
		} else if strings.Contains(lower, "i/o error") || strings.Contains(lower, "btrfs") || strings.Contains(lower, "ext4") {
			title = "Cảnh báo lỗi đọc/ghi ổ đĩa hệ thống"
			suggestion = "Kiểm tra sức khỏe ổ đĩa bằng `sudo smartctl` hoặc rà soát phân vùng trong `/etc/nixos/hardware-configuration.nix`."
		} else if strings.Contains(lower, "drm") || strings.Contains(lower, "amdgpu") || strings.Contains(lower, "nvidia") || strings.Contains(lower, "i915") {
			title = "Cảnh báo trình điều khiển đồ họa (GPU Driver)"
			suggestion = "Kiểm tra thiết lập GPU kernel module trong `/etc/nixos/configuration.nix`."
		}

		if title != "" && !seenPatterns[title] {
			seenPatterns[title] = true
			issue := SystemIssue{
				ID:          fmt.Sprintf("log_%d", time.Now().UnixNano()),
				Type:        "systemd_error",
				Severity:    "warning",
				Title:       title,
				Description: line,
				Suggestion:  suggestion,
				Timestamp:   time.Now().Format("15:04:05"),
			}
			issues = append(issues, issue)

			// Tự động index lỗi hệ thống vào RAG để AI nắm bối cảnh
			if si.rag != nil {
				go func(iss SystemIssue) {
					_ = si.rag.IndexDocument(context.Background(), iss.ID,
						fmt.Sprintf("Lỗi hệ thống: %s\nChi tiết log: %s\nKhuyến nghị: %s", iss.Title, iss.Description, iss.Suggestion),
						map[string]string{
							"source": "journalctl",
							"title":  iss.Title,
							"domain": "system_log",
						},
					)
				}(issue)
			}
		}
	}

	return issues, nil
}

// CheckNixOSConfiguration rà soát cấu hình /etc/nixos/*.nix để tìm các vấn đề tiềm ẩn
func (si *SystemInspector) CheckNixOSConfiguration() ([]SystemIssue, error) {
	var issues []SystemIssue

	nixosDir := "/etc/nixos"
	if _, err := os.Stat(nixosDir); err != nil {
		return issues, nil
	}

	confPath := filepath.Join(nixosDir, "configuration.nix")
	data, err := os.ReadFile(confPath)
	if err == nil {
		content := string(data)

		// 1. Kiểm tra auto-optimise-store
		if !strings.Contains(content, "auto-optimise-store") {
			issues = append(issues, SystemIssue{
				ID:          "nixos_opt_store",
				Type:        "nixos_config",
				Severity:    "info",
				Title:       "Chưa bật tự động tối ưu hóa Nix Store",
				Description: "Nix Store có thể chứa nhiều tệp trùng lặp làm tốn dung lượng ổ cứng SSD.",
				Suggestion:  "Thêm `nix.settings.auto-optimise-store = true;` vào `/etc/nixos/configuration.nix` để tiết kiệm ổ đĩa.",
				FixCommand:  "bam sys-optimise",
				Timestamp:   time.Now().Format("15:04:05"),
			})
		}

		// 2. Kiểm tra garbage collection định kỳ
		if !strings.Contains(content, "nix.gc") {
			issues = append(issues, SystemIssue{
				ID:          "nixos_gc",
				Type:        "nixos_config",
				Severity:    "info",
				Title:       "Chưa cấu hình dọn rác Nix định kỳ (Nix GC)",
				Description: "Các bản dựng cũ của NixOS tích tụ lâu ngày làm đầy phân vùng gốc.",
				Suggestion:  "Cấu hình `nix.gc.automatic = true;` để tự động dọn dẹp các thế hệ kernel và package cũ mỗi tuần.",
				Timestamp:   time.Now().Format("15:04:05"),
			})
		}
	}

	return issues, nil
}

// DetectIdleBackgroundApps quét các ứng dụng đang chạy nền nhưng ít hoặc không có hoạt động
func (si *SystemInspector) DetectIdleBackgroundApps() []IdleAppReport {
	var reports []IdleAppReport
	apps := GetRunningApps()

	// Danh sách ứng dụng tiêu tốn RAM mà có thể xem xét nhắc nhở
	heavyApps := map[string]string{
		"Antigravity IDE 🚀":     "Trình soạn thảo code",
		"Firefox Web Browser 🌐": "Trình duyệt web",
		"BamAI Local LLM Server 🧠": "Mô hình ngôn ngữ cục bộ",
		"Zed Code Editor":        "Trình biên soạn code",
	}

	for _, app := range apps {
		if desc, ok := heavyApps[app.Name]; ok {
			// Nếu CPU thấp < 0.5% (đang ở trạng thái nhàn rỗi)
			cpuVal := strings.TrimSuffix(app.CPU, "%")
			if cpuVal == "0.0" || cpuVal == "0.1" || cpuVal == "0.2" {
				reports = append(reports, IdleAppReport{
					PID:         app.PID,
					Name:        app.Name,
					Command:     app.Command,
					MemoryMB:    app.Memory,
					IdleTimeMin: 45, // Ước lượng chu kỳ nhàn rỗi
					Suggestion:  fmt.Sprintf("%s đang chạy ngầm nhưng không sử dụng. Chủ nhân có muốn đóng để giải phóng RAM không?", desc),
				})
			}
		}
	}

	return reports
}
