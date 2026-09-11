package main

// ============================================================================
// settings.go — Backend cho hai bảng thiết lập trên giao diện:
//   • Bảng RAG   : bật/tắt tri thức, xưng hô, nạp tài liệu, thống kê, xoá.
//   • Bảng LLM   : nhà cung cấp, model cục bộ, tải model, API key, tham số.
//
// Mọi phản hồi đều đẩy về JS qua callback window.onXxx(...) để giao diện cập
// nhật bất đồng bộ mà không cần chặn luồng GTK.
// ============================================================================

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
	"time"
)

// ---------------------------------------------------------------------------
// Kiểu dữ liệu dùng chung giữa Go và JS
// ---------------------------------------------------------------------------

type modelInfo struct {
	Name     string `json:"name"`
	Path     string `json:"path"`
	Size     int64  `json:"size"`
	SizeText string `json:"size_text"`
	Active   bool   `json:"active"`
}

type settingsResult struct {
	OK       bool   `json:"ok"`
	Message  string `json:"message"`
	Settings Config `json:"settings"`
}

// ---------------------------------------------------------------------------
// Đọc / ghi thiết lập
// ---------------------------------------------------------------------------

func handleGetSettings() {
	if globalAI == nil {
		pushJSON("onSettingsLoaded", settingsResult{OK: false, Message: "AI chưa sẵn sàng"})
		return
	}
	pushJSON("onSettingsLoaded", settingsResult{OK: true, Settings: globalAI.cfg})
}

func handleSaveSettings(raw json.RawMessage) {
	if globalAI == nil || len(raw) == 0 {
		pushJSON("onSettingsSaved", settingsResult{OK: false, Message: "Dữ liệu không hợp lệ"})
		return
	}

	// Bắt đầu từ cấu hình hiện tại để các trường không gửi lên vẫn giữ nguyên.
	cfg := globalAI.cfg
	if err := json.Unmarshal(raw, &cfg); err != nil {
		pushJSON("onSettingsSaved", settingsResult{OK: false, Message: "JSON không hợp lệ: " + err.Error()})
		return
	}
	cfg.normalize()

	if err := saveConfig(cfg); err != nil {
		pushJSON("onSettingsSaved", settingsResult{OK: false, Message: "Không ghi được cấu hình: " + err.Error()})
		return
	}

	globalAI.cfg = cfg
	pushJSON("onSettingsSaved", settingsResult{OK: true, Message: "Đã lưu thiết lập", Settings: cfg})
}

// ---------------------------------------------------------------------------
// Quản lý model GGUF cục bộ
// ---------------------------------------------------------------------------

func handleListModels() {
	if globalAI == nil {
		pushJSON("onModelsListed", map[string]any{"ok": false, "message": "AI chưa sẵn sàng"})
		return
	}

	dir := globalAI.cfg.ModelDir
	_ = os.MkdirAll(dir, 0o777)

	entries, err := os.ReadDir(dir)
	if err != nil {
		pushJSON("onModelsListed", map[string]any{"ok": false, "message": "Không đọc được thư mục model: " + err.Error()})
		return
	}

	models := make([]modelInfo, 0, len(entries))
	for _, entry := range entries {
		if entry.IsDir() || !strings.HasSuffix(strings.ToLower(entry.Name()), ".gguf") {
			continue
		}
		info, err := entry.Info()
		if err != nil {
			continue
		}
		full := filepath.Join(dir, entry.Name())
		models = append(models, modelInfo{
			Name:     entry.Name(),
			Path:     full,
			Size:     info.Size(),
			SizeText: humanSize(info.Size()),
			Active:   full == globalAI.cfg.ModelPath,
		})
	}
	sort.Slice(models, func(i, j int) bool { return models[i].Name < models[j].Name })

	pushJSON("onModelsListed", map[string]any{
		"ok":      true,
		"dir":     dir,
		"active":  globalAI.cfg.ModelPath,
		"models":  models,
		"running": !globalAI.IsAIOffline(),
	})
}

func handleDownloadModel(raw json.RawMessage) {
	var req struct {
		URL  string `json:"url"`
		Name string `json:"name"`
	}
	if err := json.Unmarshal(raw, &req); err != nil || req.URL == "" {
		pushJSON("onModelDownloadError", map[string]any{"ok": false, "message": "URL không hợp lệ"})
		return
	}
	if globalAI == nil {
		pushJSON("onModelDownloadError", map[string]any{"ok": false, "message": "AI chưa sẵn sàng"})
		return
	}

	// Suy ra tên file từ URL nếu người dùng để trống.
	name := strings.TrimSpace(req.Name)
	if name == "" {
		base := filepath.Base(strings.Split(req.URL, "?")[0])
		name = base
	}
	if !strings.HasSuffix(strings.ToLower(name), ".gguf") {
		name += ".gguf"
	}
	name = filepath.Base(name) // chống path traversal

	dir := globalAI.cfg.ModelDir
	_ = os.MkdirAll(dir, 0o777)
	dest := filepath.Join(dir, name)
	tmp := dest + ".download"

	client := &http.Client{Timeout: 0} // tải model có thể rất lâu
	resp, err := client.Get(req.URL)
	if err != nil {
		pushJSON("onModelDownloadError", map[string]any{"ok": false, "message": "Không kết nối được: " + err.Error()})
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		pushJSON("onModelDownloadError", map[string]any{"ok": false, "message": fmt.Sprintf("Máy chủ trả về mã %d", resp.StatusCode)})
		return
	}

	out, err := os.Create(tmp)
	if err != nil {
		pushJSON("onModelDownloadError", map[string]any{"ok": false, "message": err.Error()})
		return
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
				pushJSON("onModelDownloadError", map[string]any{"ok": false, "message": writeErr.Error()})
				return
			}
			written += int64(n)
			if time.Since(lastReport) > 700*time.Millisecond {
				lastReport = time.Now()
				pushJSON("onModelDownloadProgress", map[string]any{
					"ok":       true,
					"name":     name,
					"received": written,
					"total":    total,
					"percent":  percentOf(written, total),
					"text":     fmt.Sprintf("%s / %s", humanSize(written), humanSize(total)),
				})
			}
		}
		if readErr == io.EOF {
			break
		}
		if readErr != nil {
			out.Close()
			_ = os.Remove(tmp)
			pushJSON("onModelDownloadError", map[string]any{"ok": false, "message": "Lỗi tải: " + readErr.Error()})
			return
		}
	}

	if err := out.Close(); err != nil {
		_ = os.Remove(tmp)
		pushJSON("onModelDownloadError", map[string]any{"ok": false, "message": err.Error()})
		return
	}
	if err := os.Rename(tmp, dest); err != nil {
		pushJSON("onModelDownloadError", map[string]any{"ok": false, "message": err.Error()})
		return
	}

	pushJSON("onModelDownloaded", map[string]any{
		"ok":   true,
		"name": name,
		"path": dest,
		"text": humanSize(written),
	})
}

func handleSetActiveModel(raw json.RawMessage) {
	if globalAI == nil {
		pushJSON("onActiveModelSet", map[string]any{"ok": false, "message": "AI chưa sẵn sàng"})
		return
	}

	var req struct {
		Path string `json:"path"`
	}
	if err := json.Unmarshal(raw, &req); err != nil || req.Path == "" {
		pushJSON("onActiveModelSet", map[string]any{"ok": false, "message": "Đường dẫn model không hợp lệ"})
		return
	}
	if _, err := os.Stat(req.Path); err != nil {
		pushJSON("onActiveModelSet", map[string]any{"ok": false, "message": "Không tìm thấy file model: " + req.Path})
		return
	}

	cfg := globalAI.cfg
	cfg.ModelPath = req.Path
	cfg.normalize()
	if err := saveConfig(cfg); err != nil {
		pushJSON("onActiveModelSet", map[string]any{"ok": false, "message": err.Error()})
		return
	}
	globalAI.cfg = cfg

	// Khởi động lại llama-server với model mới.
	if err := restartAIServer(req.Path); err != nil {
		pushJSON("onActiveModelSet", map[string]any{
			"ok":      false,
			"message": err.Error(),
			"path":    req.Path,
		})
		return
	}

	// Chờ server sẵn sàng (tối đa ~20 giây) rồi báo kết quả.
	go func() {
		for i := 0; i < 40; i++ {
			time.Sleep(500 * time.Millisecond)
			if !globalAI.IsAIOffline() {
				pushJSON("onActiveModelSet", map[string]any{
					"ok":      true,
					"message": "Đã chuyển sang model: " + filepath.Base(req.Path),
					"path":    req.Path,
				})
				return
			}
		}
		pushJSON("onActiveModelSet", map[string]any{
			"ok":      false,
			"message": "Model đã được chọn nhưng llama-server chưa phản hồi. Hãy thử lại sau ít giây.",
			"path":    req.Path,
		})
	}()
}

// ---------------------------------------------------------------------------
// Kiểm tra kết nối LLM
// ---------------------------------------------------------------------------

func handleTestLLM() {
	if globalAI == nil {
		pushJSON("onLLMTestResult", map[string]any{"ok": false, "message": "AI chưa sẵn sàng"})
		return
	}
	cfg := globalAI.cfg

	switch cfg.Provider {
	case "local":
		if globalAI.IsAIOffline() {
			pushJSON("onLLMTestResult", map[string]any{
				"ok":      false,
				"message": "llama-server chưa chạy tại " + cfg.LlamaHost + ". Hãy bấm “Khởi động AI”.",
			})
			return
		}
		pushJSON("onLLMTestResult", map[string]any{"ok": true, "message": "llama-server đang hoạt động tốt tại " + cfg.LlamaHost})
	case "deepseek", "openai", "gemini":
		endpoint, key := providerEndpoint(cfg)
		if key == "" {
			pushJSON("onLLMTestResult", map[string]any{"ok": false, "message": "Chưa nhập API key cho nhà cung cấp " + cfg.Provider})
			return
		}
		client := &http.Client{Timeout: 6 * time.Second}
		req, _ := http.NewRequest(http.MethodGet, endpoint, nil)
		req.Header.Set("Authorization", "Bearer "+key)
		resp, err := client.Do(req)
		if err != nil {
			pushJSON("onLLMTestResult", map[string]any{"ok": false, "message": "Không kết nối được " + endpoint + ": " + err.Error()})
			return
		}
		defer resp.Body.Close()
		// 401/403 = key sai; các mã khác (kể cả 404) nghĩa là endpoint sống.
		if resp.StatusCode == http.StatusUnauthorized || resp.StatusCode == http.StatusForbidden {
			pushJSON("onLLMTestResult", map[string]any{"ok": false, "message": "API key bị từ chối (mã " + fmt.Sprint(resp.StatusCode) + ")"})
			return
		}
		pushJSON("onLLMTestResult", map[string]any{"ok": true, "message": "Kết nối tới " + cfg.Provider + " thành công (mã " + fmt.Sprint(resp.StatusCode) + ")"})
	default:
		pushJSON("onLLMTestResult", map[string]any{"ok": false, "message": "Nhà cung cấp không xác định: " + cfg.Provider})
	}
}

func providerEndpoint(cfg Config) (endpoint string, key string) {
	switch cfg.Provider {
	case "deepseek":
		return "https://api.deepseek.com/models", cfg.DeepSeekKey
	case "openai":
		return "https://api.openai.com/v1/models", cfg.OpenAIKey
	case "gemini":
		return "https://generativelanguage.googleapis.com/v1beta/openai/models", cfg.GeminiKey
	}
	return "", ""
}

// ---------------------------------------------------------------------------
// Tri thức RAG
// ---------------------------------------------------------------------------

type knowledgeDoc struct {
	Name    string `json:"name"`
	Content string `json:"content"`
}

func handleRagStats() {
	if globalAI == nil || globalAI.rag == nil {
		pushJSON("onRagStats", map[string]any{"ok": false, "message": "RAG chưa sẵn sàng", "count": 0})
		return
	}
	pushJSON("onRagStats", map[string]any{
		"ok":     true,
		"count":  globalAI.rag.DocumentCount(),
		"path":   globalAI.cfg.RAGDBPath,
		"top_k":  globalAI.cfg.RAGTopK,
		"enable": globalAI.cfg.EnableRAG,
	})
}

func handleRagAddDocuments(raw json.RawMessage) {
	if globalAI == nil || globalAI.rag == nil {
		pushJSON("onRagIndexed", map[string]any{"ok": false, "message": "RAG chưa sẵn sàng"})
		return
	}

	var req struct {
		Documents []knowledgeDoc `json:"documents"`
	}
	if err := json.Unmarshal(raw, &req); err != nil || len(req.Documents) == 0 {
		pushJSON("onRagIndexed", map[string]any{"ok": false, "message": "Không có tài liệu để nạp"})
		return
	}

	// Embedding do llama-server cung cấp → phải đảm bảo AI đã chạy.
	if globalAI.IsAIOffline() {
		pushJSON("onRagIndexProgress", map[string]any{"ok": true, "message": "Đang bật AI để tạo vector embedding…"})
		if !ensureAIReady(true) {
			pushJSON("onRagIndexed", map[string]any{"ok": false, "message": "Không khởi động được llama-server để tạo embedding."})
			return
		}
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
	defer cancel()

	added := 0
	var failures []string
	for i, doc := range req.Documents {
		content := strings.TrimSpace(doc.Content)
		if content == "" {
			failures = append(failures, doc.Name+" (rỗng)")
			continue
		}
		id := fmt.Sprintf("%s_%d", filepath.Base(doc.Name), time.Now().UnixNano())
		err := globalAI.rag.IndexDocument(ctx, id, content, map[string]string{
			"source": doc.Name,
			"title":  filepath.Base(doc.Name),
		})
		if err != nil {
			failures = append(failures, doc.Name+" ("+err.Error()+")")
		} else {
			added++
		}
		pushJSON("onRagIndexProgress", map[string]any{
			"ok":    true,
			"index": i + 1,
			"total": len(req.Documents),
			"name":  doc.Name,
		})
	}

	pushJSON("onRagIndexed", map[string]any{
		"ok":       len(failures) == 0,
		"added":    added,
		"total":    len(req.Documents),
		"failures": failures,
		"count":    globalAI.rag.DocumentCount(),
		"message":  fmt.Sprintf("Đã nạp %d/%d tài liệu vào tri thức.", added, len(req.Documents)),
	})
}

func handleRagClear() {
	if globalAI == nil || globalAI.rag == nil {
		pushJSON("onRagCleared", map[string]any{"ok": false, "message": "RAG chưa sẵn sàng"})
		return
	}
	if err := globalAI.rag.Reset(); err != nil {
		pushJSON("onRagCleared", map[string]any{"ok": false, "message": err.Error()})
		return
	}
	pushJSON("onRagCleared", map[string]any{"ok": true, "message": "Đã xoá toàn bộ tri thức.", "count": 0})
}

func handleRagListDocuments() {
	if globalAI == nil || globalAI.rag == nil {
		pushJSON("onRagDocumentsListed", map[string]any{"ok": false, "documents": []any{}})
		return
	}
	docs, err := globalAI.rag.ListDocuments()
	if err != nil {
		pushJSON("onRagDocumentsListed", map[string]any{"ok": false, "error": err.Error()})
		return
	}
	pushJSON("onRagDocumentsListed", map[string]any{"ok": true, "documents": docs})
}

func handleRagDeleteDoc(raw json.RawMessage) {
	if globalAI == nil || globalAI.rag == nil {
		pushJSON("onRagDocDeleted", map[string]any{"ok": false, "message": "RAG chưa sẵn sàng"})
		return
	}
	var req struct {
		Source string `json:"source"`
	}
	if err := json.Unmarshal(raw, &req); err != nil || req.Source == "" {
		pushJSON("onRagDocDeleted", map[string]any{"ok": false, "message": "Nguồn tài liệu không hợp lệ"})
		return
	}
	err := globalAI.rag.DeleteDocumentBySource(req.Source)
	if err != nil {
		pushJSON("onRagDocDeleted", map[string]any{"ok": false, "message": err.Error()})
		return
	}
	pushJSON("onRagDocDeleted", map[string]any{"ok": true, "message": "Đã xoá tài liệu khỏi tri thức", "count": globalAI.rag.DocumentCount()})
}

// ---------------------------------------------------------------------------
// System Inspector & NixOS Config Handlers
// ---------------------------------------------------------------------------

func handleSystemInspect() {
	if globalAI == nil || globalAI.inspector == nil {
		pushJSON("onSystemInspected", map[string]any{"ok": false, "message": "Hệ thống chưa sẵn sàng"})
		return
	}
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	logIssues, _ := globalAI.inspector.InspectRecentLogs(ctx)
	nixosIssues, _ := globalAI.inspector.CheckNixOSConfiguration()
	idleApps := globalAI.inspector.DetectIdleBackgroundApps()

	allIssues := append(logIssues, nixosIssues...)
	pushJSON("onSystemInspected", map[string]any{
		"ok":        true,
		"issues":    allIssues,
		"idle_apps": idleApps,
		"time":      time.Now().Format("15:04:05"),
	})
}

// ---------------------------------------------------------------------------
// WakaTracker Handlers
// ---------------------------------------------------------------------------

func handleWakaStats() {
	if globalAI == nil || globalAI.waka == nil {
		pushJSON("onWakaStats", map[string]any{"ok": false, "message": "WakaTracker chưa sẵn sàng"})
		return
	}
	summary := globalAI.waka.GetSummary()
	summary["ok"] = true
	pushJSON("onWakaStats", summary)
}

func handleAddReminder(raw json.RawMessage) {
	if globalAI == nil || globalAI.waka == nil {
		return
	}
	var req struct {
		Title   string `json:"title"`
		DueTime string `json:"due_time"`
	}
	if err := json.Unmarshal(raw, &req); err == nil && req.Title != "" {
		r := globalAI.waka.AddReminder(req.Title, req.DueTime)
		pushJSON("onReminderAdded", map[string]any{"ok": true, "reminder": r})
	}
}

func handleToggleReminder(raw json.RawMessage) {
	if globalAI == nil || globalAI.waka == nil {
		return
	}
	var req struct {
		ID string `json:"id"`
	}
	if err := json.Unmarshal(raw, &req); err == nil && req.ID != "" {
		globalAI.waka.ToggleReminder(req.ID)
		pushJSON("onReminderToggled", map[string]any{"ok": true, "id": req.ID})
	}
}

// ---------------------------------------------------------------------------
// User Profile & Onboarding Quiz Handlers
// ---------------------------------------------------------------------------

func handleGetProfile() {
	if globalAI == nil || globalAI.profile == nil {
		pushJSON("onProfileLoaded", map[string]any{"ok": false})
		return
	}
	pushJSON("onProfileLoaded", map[string]any{
		"ok":      true,
		"profile": globalAI.profile.Profile,
	})
}

func handleUpdateProfile(raw json.RawMessage) {
	if globalAI == nil || globalAI.profile == nil {
		return
	}
	var p UserProfileData
	if err := json.Unmarshal(raw, &p); err == nil {
		globalAI.profile.UpdateProfile(p)
		pushJSON("onProfileUpdated", map[string]any{
			"ok":      true,
			"profile": globalAI.profile.Profile,
			"message": "Đã cập nhật thông tin hồ sơ",
		})
	}
}

func handleGetQuiz() {
	if globalAI == nil || globalAI.profile == nil {
		pushJSON("onQuizQuestions", map[string]any{"ok": false})
		return
	}
	qs := globalAI.profile.GetQuizQuestions()
	pushJSON("onQuizQuestions", map[string]any{
		"ok":        true,
		"questions": qs,
	})
}

func handleSubmitQuiz(raw json.RawMessage) {
	if globalAI == nil || globalAI.profile == nil {
		return
	}
	var req struct {
		Answers map[int]int `json:"answers"`
	}
	if err := json.Unmarshal(raw, &req); err == nil {
		result := globalAI.profile.SubmitAssessment(req.Answers)
		result["ok"] = true
		pushJSON("onQuizSubmitted", result)
	}
}

// ---------------------------------------------------------------------------
// Khởi động / khởi động lại llama-server
// ---------------------------------------------------------------------------

func handleRestartAI() {
	if globalAI == nil {
		pushJSON("onAIRestarted", map[string]any{"ok": false, "message": "AI chưa sẵn sàng"})
		return
	}
	if err := restartAIServer(globalAI.cfg.ModelPath); err != nil {
		pushJSON("onAIRestarted", map[string]any{"ok": false, "message": err.Error()})
		return
	}
	go func() {
		if ensureAIReady(false) {
			pushJSON("onAIRestarted", map[string]any{"ok": true, "message": "llama-server đã sẵn sàng."})
			return
		}
		pushJSON("onAIRestarted", map[string]any{"ok": false, "message": "llama-server chưa phản hồi sau khi khởi động lại."})
	}()
}

// restartAIServer dừng llama-server hiện tại rồi chạy lại với model chỉ định.
func restartAIServer(modelPath string) error {
	_ = exec.Command("pkill", "-f", "llama-server").Run()
	time.Sleep(700 * time.Millisecond)

	cmd := exec.Command("bamos-ai-server")
	if globalAI != nil {
		cmd.Env = globalAI.aiServerEnv(modelPath)
	} else {
		cmd.Env = append(os.Environ(), "BAMAI_MODEL_PATH="+modelPath)
	}
	if err := cmd.Start(); err != nil {
		return fmt.Errorf("không khởi động được llama-server: %w", err)
	}
	return nil
}

// ensureAIReady đảm bảo llama-server đang chạy (dùng chung với EnsureServices).
// Khi announce=true, tiến trình hiện tại gửi thông báo tiến độ về giao diện.
func ensureAIReady(announce bool) bool {
	if globalAI == nil {
		return false
	}
	if !globalAI.IsAIOffline() {
		return true
	}

	if announce {
		pushJSON("onRagIndexProgress", map[string]any{"ok": true, "message": "Đang bật AI…"})
	}
	if err := globalAI.startAIServer(); err != nil {
		fmt.Printf("[BamAI Settings] Không khởi động được llama-server: %v\n", err)
	}
	return globalAI.waitAIReady(30 * time.Second)
}

// ---------------------------------------------------------------------------
// Tiện ích
// ---------------------------------------------------------------------------

func humanSize(bytes int64) string {
	if bytes <= 0 {
		return "0 B"
	}
	units := []string{"B", "KB", "MB", "GB", "TB"}
	value := float64(bytes)
	idx := 0
	for value >= 1024 && idx < len(units)-1 {
		value /= 1024
		idx++
	}
	return fmt.Sprintf("%.1f %s", value, units[idx])
}

func percentOf(part, total int64) int {
	if total <= 0 {
		return 0
	}
	return int(part * 100 / total)
}
