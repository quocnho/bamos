package gui

import "C"
import (
	"context"
	"encoding/json"
	"fmt"
	"net/url"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"troly/backend/internal/domain"
	"troly/backend/internal/platform/llm"
	"troly/backend/internal/repository/fs"
	"troly/backend/internal/repository/sqlite"
	"troly/backend/internal/usecase/chat"
	"troly/backend/internal/usecase/profile"
	"troly/backend/internal/usecase/settings"
	"troly/backend/internal/usecase/system"
	"troly/backend/internal/usecase/waka"
)

type Dispatcher struct {
	cfgStore    *fs.ConfigStore
	ragRepo     *sqlite.RAGRepo
	memRepo     *sqlite.MemoryRepo
	toolRepo    *fs.ToolRepo
	profileRepo *fs.ProfileRepo
	wakaRepo    *fs.WakaRepo
	llamaServer *llm.LlamaServer
	chatUc      *chat.ChatUsecase
	profileUc   *profile.ProfileUsecase
	wakaUc      *waka.WakaUsecase
	inspectUc   *system.InspectUsecase
	modelMgr    *settings.ModelManager

	currentCancel context.CancelFunc
}

var globalDispatcher *Dispatcher

func SetGlobalDispatcher(d *Dispatcher) {
	globalDispatcher = d
}

func (d *Dispatcher) Dispatch(msg domain.NativeMessage) {
	switch msg.Action {
	case "drag":
		TriggerWindowDrag()
	case "close":
		if d.llamaServer != nil {
			go d.llamaServer.Stop()
		}
		TriggerWindowClose()
	case "set_always_on_top":
		TriggerWindowSetKeepAbove(msg.AlwaysOnTop)
	case "activate_and_raise":
		TriggerWindowShow()
	case "raise_notification":
		TriggerWindowRaiseNotification()
	case "stop":
		if d.currentCancel != nil {
			d.currentCancel()
			d.currentCancel = nil
		}
	case "set_fullscreen":
		TriggerWindowFullscreen(msg.Fullscreen)
	case "window_fit":
		TriggerWindowFit(msg.Width, msg.Height)
	case "window_full":
		TriggerWindowSetFull(msg.Full)
	case "open_url":
		d.handleOpenURL(msg.Payload)
	case "get_idle_time":
		go func() {
			idleMs := getMutterIdleTimeMs()
			EvalJS(fmt.Sprintf("window.onIdleTimeUpdate && window.onIdleTimeUpdate(%d);", idleMs))
		}()
	case "set_directory":
		if d.memRepo != nil {
			d.memRepo.SetActiveDirectory(msg.Directory)
		}
	case "clear_directory":
		if d.memRepo != nil {
			d.memRepo.SetActiveDirectory("")
		}
	case "wake_ai", "ensure_services":
		if d.llamaServer != nil {
			go d.llamaServer.EnsureRunning(
				func(progressMsg string) {
					PushJSON("onAIWaking", progressMsg)
				},
				func(started bool) {
					EvalJS(fmt.Sprintf("window.onAIReady && window.onAIReady(%t);", started))
				},
			)
		}
	case "ask":
		d.handleAsk(msg)

	// ---- Settings ----
	case "get_settings":
		go d.handleGetSettings()
	case "save_settings":
		go d.handleSaveSettings(msg.Payload)
	case "list_models":
		go d.handleListModels()
	case "download_model":
		go d.handleDownloadModel(msg.Payload)
	case "set_active_model":
		go d.handleSetActiveModel(msg.Payload)
	case "test_llm":
		go d.handleTestLLM()

	// ---- RAG ----
	case "rag_add_documents":
		go d.handleRagAddDocuments(msg.Payload)
	case "rag_stats":
		go d.handleRagStats()
	case "rag_clear":
		go d.handleRagClear()
	case "rag_list_documents":
		go d.handleRagListDocuments()
	case "rag_delete_doc":
		go d.handleRagDeleteDoc(msg.Payload)

	// ---- System ----
	case "system_inspect":
		go d.handleSystemInspect()

	// ---- Waka ----
	case "waka_stats":
		go d.handleWakaStats()
	case "add_reminder":
		go d.handleAddReminder(msg.Payload)
	case "toggle_reminder":
		go d.handleToggleReminder(msg.Payload)

	// ---- Profile ----
	case "get_profile":
		go d.handleGetProfile()
	case "update_profile":
		go d.handleUpdateProfile(msg.Payload)
	case "get_quiz":
		go d.handleGetQuiz()
	case "submit_quiz":
		go d.handleSubmitQuiz(msg.Payload)
	}
}

func (d *Dispatcher) handleAsk(msg domain.NativeMessage) {
	if d.chatUc == nil {
		return
	}
	if d.currentCancel != nil {
		d.currentCancel()
	}
	ctx, cancel := context.WithCancel(context.Background())
	d.currentCancel = cancel

	go func() {
		defer func() {
			d.currentCancel = nil
		}()
		isFirst := true
		d.chatUc.AskStream(
			ctx,
			msg.Question,
			msg.UseRAG,
			msg.History,
			func(chunk string) {
				EvalJS(fmt.Sprintf("window.onAIChunk && window.onAIChunk('%s', %t);", EscapeJSString(chunk), isFirst))
				isFirst = false
			},
			func() {
				EvalJS("window.onAIDone && window.onAIDone();")
			},
			func(errMsg string) {
				EvalJS(fmt.Sprintf("window.onAIError && window.onAIError('%s');", EscapeJSString(errMsg)))
			},
		)
	}()
}

func (d *Dispatcher) handleOpenURL(payload json.RawMessage) {
	var req struct {
		URL string `json:"url"`
	}
	if err := json.Unmarshal(payload, &req); err != nil {
		return
	}
	raw := strings.TrimSpace(req.URL)
	parsed, err := url.Parse(raw)
	if err != nil || parsed.Host == "" || (parsed.Scheme != "http" && parsed.Scheme != "https") {
		return
	}
	TriggerOpenURL(parsed.String())
}

func getMutterIdleTimeMs() int64 {
	cmd := exec.Command("gdbus", "call", "--session", "--dest", "org.gnome.Mutter.IdleMonitor",
		"--object-path", "/org/gnome/Mutter/IdleMonitor/Core",
		"--method", "org.gnome.Mutter.IdleMonitor.GetIdletime")
	out, err := cmd.Output()
	if err != nil {
		return 0
	}
	s := strings.TrimSpace(string(out))
	s = strings.TrimPrefix(s, "(uint64 ")
	s = strings.TrimSuffix(s, ",)")
	s = strings.TrimSpace(s)
	var val int64
	_, _ = fmt.Sscanf(s, "%d", &val)
	return val
}

// Handlers con
func (d *Dispatcher) handleGetSettings() {
	cfg := d.cfgStore.LoadConfig()
	PushJSON("onSettingsLoaded", map[string]any{"ok": true, "settings": cfg})
}

func (d *Dispatcher) handleSaveSettings(raw json.RawMessage) {
	cfg := d.cfgStore.LoadConfig()
	if err := json.Unmarshal(raw, &cfg); err != nil {
		PushErrorJSON("onSettingsSaved", "JSON không hợp lệ: "+err.Error())
		return
	}
	if err := d.cfgStore.SaveConfig(cfg); err != nil {
		PushErrorJSON("onSettingsSaved", "Không lưu được cấu hình: "+err.Error())
		return
	}
	d.chatUc.UpdateConfig(cfg)
	d.llamaServer.UpdateConfig(cfg)
	PushJSON("onSettingsSaved", map[string]any{"ok": true, "message": "Đã lưu thiết lập", "settings": cfg})
}

func (d *Dispatcher) handleListModels() {
	cfg := d.cfgStore.LoadConfig()
	models, err := d.modelMgr.ListModels(cfg.ModelPath, cfg.ModelDir)
	if err != nil {
		PushErrorJSON("onModelsListed", err.Error())
		return
	}
	PushJSON("onModelsListed", map[string]any{
		"ok":      true,
		"dir":     cfg.ModelDir,
		"active":  cfg.ModelPath,
		"models":  models,
		"running": !d.llamaServer.IsOffline(),
	})
}

func (d *Dispatcher) handleDownloadModel(raw json.RawMessage) {
	var req struct {
		URL  string `json:"url"`
		Name string `json:"name"`
	}
	if err := json.Unmarshal(raw, &req); err != nil || req.URL == "" {
		PushErrorJSON("onModelDownloadError", "URL không hợp lệ")
		return
	}
	cfg := d.cfgStore.LoadConfig()
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	modelName := strings.TrimSpace(req.Name)
	if modelName == "" {
		modelName = filepath.Base(strings.Split(req.URL, "?")[0])
	}
	dest, err := d.modelMgr.DownloadModel(ctx, req.URL, req.Name, cfg.ModelDir, func(written, total int64) {
		PushJSON("onModelDownloadProgress", map[string]any{
			"ok":       true,
			"name":     modelName,
			"received": written,
			"total":    total,
			"percent":  settings.PercentOf(written, total),
			"text":     fmt.Sprintf("%s / %s", settings.HumanSize(written), settings.HumanSize(total)),
		})
	})
	if err != nil {
		PushErrorJSON("onModelDownloadError", err.Error())
		return
	}
	PushJSON("onModelDownloaded", map[string]any{
		"ok":   true,
		"name": filepath.Base(dest),
		"path": dest,
	})
}

func (d *Dispatcher) handleSetActiveModel(raw json.RawMessage) {
	var req struct {
		Path string `json:"path"`
	}
	if err := json.Unmarshal(raw, &req); err != nil || req.Path == "" {
		PushErrorJSON("onActiveModelSet", "Đường dẫn model không hợp lệ")
		return
	}
	cfg := d.cfgStore.LoadConfig()
	cfg.ModelPath = req.Path
	_ = d.cfgStore.SaveConfig(cfg)
	d.llamaServer.UpdateConfig(cfg)
	d.llamaServer.Stop()
	_ = d.llamaServer.Start()
	PushJSON("onActiveModelSet", map[string]any{
		"ok":      true,
		"message": "Đã đổi model sang: " + filepath.Base(req.Path),
		"path":    req.Path,
	})
}

func (d *Dispatcher) handleTestLLM() {
	cfg := d.cfgStore.LoadConfig()
	ok, msg := d.modelMgr.TestLLM(cfg, d.llamaServer.IsOffline())
	PushJSON("onLLMTestResult", map[string]any{"ok": ok, "message": msg})
}

func (d *Dispatcher) handleRagStats() {
	cfg := d.cfgStore.LoadConfig()
	count := d.ragRepo.DocumentCount()
	PushJSON("onRagStats", map[string]any{
		"ok":     true,
		"count":  count,
		"path":   cfg.RAGDBPath,
		"top_k":  cfg.RAGTopK,
		"enable": cfg.EnableRAG,
	})
}

func (d *Dispatcher) handleRagAddDocuments(raw json.RawMessage) {
	var req struct {
		Documents []struct {
			Name    string `json:"name"`
			Content string `json:"content"`
		} `json:"documents"`
	}
	if err := json.Unmarshal(raw, &req); err != nil || len(req.Documents) == 0 {
		PushErrorJSON("onRagIndexed", "Không có tài liệu để nạp")
		return
	}
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
	defer cancel()

	added := 0
	for i, doc := range req.Documents {
		id := fmt.Sprintf("%s_%d", filepath.Base(doc.Name), time.Now().UnixNano())
		err := d.ragRepo.IndexDocument(ctx, id, doc.Content, map[string]string{
			"source": doc.Name,
			"title":  filepath.Base(doc.Name),
		})
		if err == nil {
			added++
		}
		PushJSON("onRagIndexProgress", map[string]any{
			"ok":    true,
			"index": i + 1,
			"total": len(req.Documents),
			"name":  doc.Name,
		})
	}
	PushJSON("onRagIndexed", map[string]any{
		"ok":      true,
		"added":   added,
		"total":   len(req.Documents),
		"count":   d.ragRepo.DocumentCount(),
		"message": fmt.Sprintf("Đã nạp %d/%d tài liệu vào tri thức.", added, len(req.Documents)),
	})
}

func (d *Dispatcher) handleRagClear() {
	if err := d.ragRepo.Reset(); err != nil {
		PushErrorJSON("onRagCleared", err.Error())
		return
	}
	PushJSON("onRagCleared", map[string]any{"ok": true, "message": "Đã xoá toàn bộ tri thức.", "count": 0})
}

func (d *Dispatcher) handleRagListDocuments() {
	docs, err := d.ragRepo.ListDocuments()
	if err != nil {
		PushJSON("onRagDocumentsListed", map[string]any{"ok": false, "documents": []any{}})
		return
	}
	PushJSON("onRagDocumentsListed", map[string]any{"ok": true, "documents": docs})
}

func (d *Dispatcher) handleRagDeleteDoc(raw json.RawMessage) {
	var req struct {
		Source string `json:"source"`
	}
	if err := json.Unmarshal(raw, &req); err != nil || req.Source == "" {
		return
	}
	_ = d.ragRepo.DeleteDocumentBySource(req.Source)
	d.handleRagListDocuments()
}

func (d *Dispatcher) handleSystemInspect() {
	ctx := context.Background()
	logs, _ := d.inspectUc.InspectRecentLogs(ctx)
	confs, _ := d.inspectUc.CheckNixOSConfiguration()
	idle := d.inspectUc.DetectIdleBackgroundApps()
	issues := append(logs, confs...)
	PushJSON("onSystemInspected", map[string]any{
		"ok":        true,
		"issues":    issues,
		"idle_apps": idle,
	})
}

func (d *Dispatcher) handleWakaStats() {
	sum := d.wakaUc.GetSummary()
	PushJSON("onWakaStats", map[string]any{
		"ok":      true,
		"summary": sum,
	})
}

func (d *Dispatcher) handleAddReminder(raw json.RawMessage) {
	var req struct {
		Title   string `json:"title"`
		DueTime string `json:"due_time"`
	}
	if err := json.Unmarshal(raw, &req); err == nil && req.Title != "" {
		d.wakaUc.AddReminder(req.Title, req.DueTime)
		d.handleWakaStats()
	}
}

func (d *Dispatcher) handleToggleReminder(raw json.RawMessage) {
	var req struct {
		ID string `json:"id"`
	}
	if err := json.Unmarshal(raw, &req); err == nil && req.ID != "" {
		d.wakaUc.ToggleReminder(req.ID)
		d.handleWakaStats()
	}
}

func (d *Dispatcher) handleGetProfile() {
	prof := d.profileUc.GetProfile()
	PushJSON("onProfileLoaded", map[string]any{
		"ok":      true,
		"profile": prof,
		"domains": domain.AvailableDomains,
	})
}

func (d *Dispatcher) handleUpdateProfile(raw json.RawMessage) {
	var req domain.UserProfileData
	if err := json.Unmarshal(raw, &req); err == nil {
		d.profileUc.UpdateProfile(req)
		PushJSON("onProfileLoaded", map[string]any{
			"ok":      true,
			"profile": d.profileUc.GetProfile(),
			"domains": domain.AvailableDomains,
			"message": "Đã lưu hồ sơ thành công!",
		})
	}
}

func (d *Dispatcher) handleGetQuiz() {
	q := d.profileUc.GetQuizQuestions()
	PushJSON("onQuizQuestions", map[string]any{
		"ok":        true,
		"questions": q,
	})
}

func (d *Dispatcher) handleSubmitQuiz(raw json.RawMessage) {
	var req struct {
		Answers map[int]int `json:"answers"`
	}
	if err := json.Unmarshal(raw, &req); err == nil {
		res := d.profileUc.SubmitAssessment(req.Answers)
		PushJSON("onQuizSubmitted", map[string]any{
			"ok":      true,
			"result":  res,
			"profile": d.profileUc.GetProfile(),
		})
	}
}

//export handleScriptMessage
func handleScriptMessage(cMessage *C.char) {
	msgStr := C.GoString(cMessage)
	var msg domain.NativeMessage
	if err := json.Unmarshal([]byte(msgStr), &msg); err != nil {
		return
	}
	if globalDispatcher != nil {
		globalDispatcher.Dispatch(msg)
	}
}
