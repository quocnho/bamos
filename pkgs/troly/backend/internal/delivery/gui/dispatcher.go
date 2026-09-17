package gui

import "C"
import (
	"context"
	"encoding/json"
	"fmt"

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
		d.handleStop()
	case "set_fullscreen":
		TriggerWindowFullscreen(msg.Fullscreen)
	case "window_fit":
		TriggerWindowFit(msg.Width, msg.Height)
	case "window_full":
		TriggerWindowSetFull(msg.Full)
	case "set_dock_mode":
		d.handleSetDockMode(msg.Payload)
	case "set_window_scale":
		d.handleSetWindowScale(msg.Payload)
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
		d.handleWakeAI()
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

func (d *Dispatcher) handleSetDockMode(raw json.RawMessage) {
	if raw == nil {
		return
	}
	var p struct {
		Dock string `json:"dock"`
	}
	if json.Unmarshal(raw, &p) == nil && p.Dock != "" {
		SetDockPosition(p.Dock)
		cfg := d.cfgStore.LoadConfig()
		cfg.DockPosition = p.Dock
		_ = d.cfgStore.SaveConfig(cfg)
	}
}

func (d *Dispatcher) handleSetWindowScale(raw json.RawMessage) {
	if raw == nil {
		return
	}
	var p struct {
		Scale float64 `json:"scale"`
	}
	if json.Unmarshal(raw, &p) == nil && p.Scale > 0 {
		SetWindowScaleFactor(p.Scale)
		cfg := d.cfgStore.LoadConfig()
		cfg.WindowScale = p.Scale
		_ = d.cfgStore.SaveConfig(cfg)
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
