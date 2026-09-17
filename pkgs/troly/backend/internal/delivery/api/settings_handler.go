package api

import (
	"encoding/json"
	"net/http"

	"troly/backend/internal/domain"
	"troly/backend/internal/repository/fs"
	"troly/backend/internal/usecase/settings"
)

type SettingsHandler struct {
	cfgStore *fs.ConfigStore
	modelMgr *settings.ModelManager
}

func NewSettingsHandler(cfgStore *fs.ConfigStore, modelMgr *settings.ModelManager) *SettingsHandler {
	return &SettingsHandler{
		cfgStore: cfgStore,
		modelMgr: modelMgr,
	}
}

func (h *SettingsHandler) HandleGetSettings(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		Error(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	cfg := h.cfgStore.LoadConfig()
	JSON(w, http.StatusOK, cfg)
}

func (h *SettingsHandler) HandleSaveSettings(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		Error(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	var cfg domain.Config
	if err := json.NewDecoder(r.Body).Decode(&cfg); err != nil {
		Error(w, http.StatusBadRequest, "Invalid request body")
		return
	}
	if err := h.cfgStore.SaveConfig(cfg); err != nil {
		Error(w, http.StatusInternalServerError, "Failed to save config: "+err.Error())
		return
	}
	JSON(w, http.StatusOK, cfg)
}

func (h *SettingsHandler) HandleListModels(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		Error(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	cfg := h.cfgStore.LoadConfig()
	models, err := h.modelMgr.ListModels(cfg.ModelPath, cfg.ModelDir)
	if err != nil {
		Error(w, http.StatusInternalServerError, err.Error())
		return
	}
	JSON(w, http.StatusOK, map[string]interface{}{
		"models": models,
		"active": cfg.ModelPath,
		"dir":    cfg.ModelDir,
	})
}
