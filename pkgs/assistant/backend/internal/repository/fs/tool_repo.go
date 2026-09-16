package fs

import (
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"strings"
)

type ToolRepo struct {
	homeDir string
}

func NewToolRepo() *ToolRepo {
	home, _ := os.UserHomeDir()
	return &ToolRepo{homeDir: home}
}

// FindFiles quét nhanh tìm tệp tin theo từ khóa hoặc đuôi mở rộng
func (ft *ToolRepo) FindFiles(query string, maxResults int) []string {
	if maxResults <= 0 {
		maxResults = 10
	}

	query = strings.ToLower(strings.TrimSpace(query))
	if query == "" {
		return nil
	}

	searchDirs := []string{
		filepath.Join(ft.homeDir, "Documents"),
		filepath.Join(ft.homeDir, "Downloads"),
		filepath.Join(ft.homeDir, "Desktop"),
		"/etc/nixos",
		ft.homeDir,
	}

	var results []string
	seen := make(map[string]bool)

	skipDirs := map[string]bool{
		".git":         true,
		".cache":       true,
		"node_modules": true,
		"target":       true,
		".local":       true,
		".cargo":       true,
		".npm":         true,
		".mozilla":     true,
		"vendor":       true,
		"proc":         true,
		"sys":          true,
		"nix":          true,
	}

	for _, root := range searchDirs {
		if _, err := os.Stat(root); err != nil {
			continue
		}

		_ = filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
			if err != nil {
				return nil
			}

			if d.IsDir() {
				name := d.Name()
				if strings.HasPrefix(name, ".") && name != "." || skipDirs[name] {
					return filepath.SkipDir
				}
				return nil
			}

			fileName := strings.ToLower(d.Name())
			if strings.Contains(fileName, query) || strings.Contains(strings.ToLower(path), query) {
				if !seen[path] {
					seen[path] = true
					results = append(results, path)
					if len(results) >= maxResults {
						return filepath.SkipAll
					}
				}
			}
			return nil
		})

		if len(results) >= maxResults {
			break
		}
	}

	return results
}

// ReadDocument đọc nội dung tệp tin văn bản hoặc cấu hình an toàn
func (ft *ToolRepo) ReadDocument(path string) (string, error) {
	if strings.HasPrefix(path, "~/") {
		path = filepath.Join(ft.homeDir, path[2:])
	}

	info, err := os.Stat(path)
	if err != nil {
		return "", fmt.Errorf("không tìm thấy file: %s", path)
	}

	if info.IsDir() {
		entries, err := os.ReadDir(path)
		if err != nil {
			return "", err
		}
		var sb strings.Builder
		sb.WriteString(fmt.Sprintf("📂 Thư mục: %s (chứa %d mục)\n", path, len(entries)))
		for i, entry := range entries {
			if i >= 30 {
				sb.WriteString(fmt.Sprintf("... và %d mục khác\n", len(entries)-30))
				break
			}
			icon := "📄"
			if entry.IsDir() {
				icon = "📁"
			}
			sb.WriteString(fmt.Sprintf("  %s %s\n", icon, entry.Name()))
		}
		return sb.String(), nil
	}

	maxBytes := int64(65536)
	file, err := os.Open(path)
	if err != nil {
		return "", err
	}
	defer file.Close()

	buf := make([]byte, maxBytes)
	n, err := file.Read(buf)
	if err != nil && n == 0 {
		return "", err
	}

	content := string(buf[:n])
	if info.Size() > maxBytes {
		content += fmt.Sprintf("\n\n[... Đã cắt bớt nội dung vì file quá dài (%d bytes) ...]", info.Size())
	}

	return content, nil
}
