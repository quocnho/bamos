package gui

import (
	"context"
	"encoding/json"
	"fmt"
	"path/filepath"
	"strings"

	"troly/backend/internal/usecase/settings"
)

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
