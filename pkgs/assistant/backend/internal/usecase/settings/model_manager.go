package settings

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"

	"bamos-assistant/backend/internal/domain"
	"bamos-assistant/backend/internal/platform/llm"
	"bamos-assistant/backend/internal/repository/fs"
)

type ModelInfo struct {
	Name     string `json:"name"`
	Path     string `json:"path"`
	Size     int64  `json:"size"`
	SizeText string `json:"size_text"`
	Active   bool   `json:"active"`
}

type ModelManager struct {
	configStore *fs.ConfigStore
	llamaServer *llm.LlamaServer
}

func NewModelManager(configStore *fs.ConfigStore, llamaServer *llm.LlamaServer) *ModelManager {
	return &ModelManager{
		configStore: configStore,
		llamaServer: llamaServer,
	}
}

func HumanSize(bytes int64) string {
	const unit = 1024
	if bytes < unit {
		return fmt.Sprintf("%d B", bytes)
	}
	div, exp := int64(unit), 0
	for n := bytes / unit; n >= unit; n /= unit {
		div *= unit
		exp++
	}
	return fmt.Sprintf("%.1f %cB", float64(bytes)/float64(div), "KMGTPE"[exp])
}

func PercentOf(val, total int64) int {
	if total <= 0 {
		return 0
	}
	p := int((float64(val) / float64(total)) * 100)
	if p > 100 {
		return 100
	}
	return p
}

func (m *ModelManager) ListModels(activePath, modelDir string) ([]ModelInfo, error) {
	_ = os.MkdirAll(modelDir, 0o777)
	entries, err := os.ReadDir(modelDir)
	if err != nil {
		return nil, err
	}

	var models []ModelInfo
	for _, entry := range entries {
		if entry.IsDir() || !strings.HasSuffix(strings.ToLower(entry.Name()), ".gguf") {
			continue
		}
		info, err := entry.Info()
		if err != nil {
			continue
		}
		full := filepath.Join(modelDir, entry.Name())
		models = append(models, ModelInfo{
			Name:     entry.Name(),
			Path:     full,
			Size:     info.Size(),
			SizeText: HumanSize(info.Size()),
			Active:   full == activePath,
		})
	}
	sort.Slice(models, func(i, j int) bool { return models[i].Name < models[j].Name })
	return models, nil
}

func (m *ModelManager) DownloadModel(ctx context.Context, url, rawName, modelDir string, onProgress func(int64, int64)) (string, error) {
	name := strings.TrimSpace(rawName)
	if name == "" {
		name = filepath.Base(strings.Split(url, "?")[0])
	}
	if !strings.HasSuffix(strings.ToLower(name), ".gguf") {
		name += ".gguf"
	}
	name = filepath.Base(name)

	_ = os.MkdirAll(modelDir, 0o777)
	dest := filepath.Join(modelDir, name)
	tmp := dest + ".download"

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return "", err
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("server returned status: %d", resp.StatusCode)
	}

	out, err := os.Create(tmp)
	if err != nil {
		return "", err
	}

	total := resp.ContentLength
	var written int64
	buf := make([]byte, 256*1024)
	lastReport := time.Now()

	for {
		n, readErr := resp.Body.Read(buf)
		if n > 0 {
			if _, writeErr := out.Write(buf[:n]); writeErr != nil {
				out.Close()
				_ = os.Remove(tmp)
				return "", writeErr
			}
			written += int64(n)
			if onProgress != nil && time.Since(lastReport) > 700*time.Millisecond {
				lastReport = time.Now()
				onProgress(written, total)
			}
		}
		if readErr == io.EOF {
			break
		}
		if readErr != nil {
			out.Close()
			_ = os.Remove(tmp)
			return "", readErr
		}
	}

	if err := out.Close(); err != nil {
		_ = os.Remove(tmp)
		return "", err
	}
	if err := os.Rename(tmp, dest); err != nil {
		return "", err
	}
	return dest, nil
}

func (m *ModelManager) TestLLM(cfg domain.Config, isLocalOffline bool) (bool, string) {
	switch cfg.Provider {
	case "local":
		if isLocalOffline {
			return false, "llama-server chưa chạy tại " + cfg.LlamaHost + ". Hãy bấm “Khởi động AI”."
		}
		return true, "llama-server đang hoạt động tốt tại " + cfg.LlamaHost
	case "deepseek", "openai", "gemini":
		var endpoint, key string
		switch cfg.Provider {
		case "deepseek":
			endpoint, key = "https://api.deepseek.com/models", cfg.DeepSeekKey
		case "openai":
			endpoint, key = "https://api.openai.com/v1/models", cfg.OpenAIKey
		case "gemini":
			endpoint, key = "https://generativelanguage.googleapis.com/v1beta/openai/models", cfg.GeminiKey
		}
		if key == "" {
			return false, "Chưa nhập API key cho nhà cung cấp " + cfg.Provider
		}
		client := &http.Client{Timeout: 6 * time.Second}
		req, _ := http.NewRequest(http.MethodGet, endpoint, nil)
		req.Header.Set("Authorization", "Bearer "+key)
		resp, err := client.Do(req)
		if err != nil {
			return false, "Không kết nối được " + endpoint + ": " + err.Error()
		}
		defer resp.Body.Close()
		if resp.StatusCode == http.StatusUnauthorized || resp.StatusCode == http.StatusForbidden {
			return false, fmt.Sprintf("API key bị từ chối (mã %d)", resp.StatusCode)
		}
		return true, fmt.Sprintf("Kết nối tới %s thành công (mã %d)", cfg.Provider, resp.StatusCode)
	default:
		return false, "Nhà cung cấp không xác định: " + cfg.Provider
	}
}
